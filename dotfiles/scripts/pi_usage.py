#!/usr/bin/env python3
"""Inspect Pi JSONL usage without charging copied fork history twice.

This is a diagnostic CLI and Waybar helper, not a shared usage service.  Pi fork
files copy entries verbatim, so a model call is owned by its stable entry id;
identical ids seen later are inherited history and are excluded.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import date, datetime, time
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

CCUSAGE_VERSION = "20.0.20"
SESSION_ID = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", re.I)


@dataclass
class Totals:
    input: int = 0
    output: int = 0
    cache_read: int = 0
    cache_write: int = 0
    cost: float = 0

    def add(self, usage: dict[str, Any], cost: float) -> None:
        self.input += number(usage.get("input"))
        self.output += number(usage.get("output"))
        self.cache_read += number(usage.get("cacheRead"))
        self.cache_write += number(usage.get("cacheWrite"))
        self.cost += cost

    def json(self) -> dict[str, Any]:
        return {
            "input_tokens": self.input,
            "output_tokens": self.output,
            "cache_read_tokens": self.cache_read,
            "cache_write_tokens": self.cache_write,
            "total_tokens": self.input + self.output + self.cache_read + self.cache_write,
            "cost_usd": round(self.cost, 8),
        }


@dataclass
class Session:
    id: str
    file: str
    parent: str | None = None
    totals: Totals = field(default_factory=Totals)
    models: set[str] = field(default_factory=set)

    def json(self) -> dict[str, Any]:
        return {
            "logical_session_id": self.id,
            "source_files": [self.file],
            "parent_session": self.parent,
            "models": sorted(self.models),
            "totals": self.totals.json(),
        }


def number(value: Any) -> int:
    return int(value) if isinstance(value, (int, float)) and not isinstance(value, bool) else 0


def cost_of(record: dict[str, Any], message: dict[str, Any]) -> tuple[float | None, dict[str, Any]]:
    """Return one of the cost shapes Pi and pi-subagents currently emit."""
    usage = message.get("usage") if isinstance(message.get("usage"), dict) else record.get("usage")
    usage = usage if isinstance(usage, dict) else {}
    cost = usage.get("cost")
    if isinstance(cost, (int, float)) and not isinstance(cost, bool):
        return float(cost), usage
    if isinstance(cost, dict) and isinstance(cost.get("total"), (int, float)):
        return float(cost["total"]), usage
    total_cost = record.get("totalCost") or message.get("totalCost")
    if isinstance(total_cost, dict) and isinstance(total_cost.get("costUsd"), (int, float)):
        return float(total_cost["costUsd"]), usage
    if isinstance(total_cost, (int, float)) and not isinstance(total_cost, bool):
        return float(total_cost), usage
    return None, usage


def event_time(record: dict[str, Any], message: dict[str, Any], tz: ZoneInfo) -> datetime | None:
    value = record.get("timestamp") or message.get("timestamp")
    if not isinstance(value, str):
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    return (parsed.replace(tzinfo=tz) if parsed.tzinfo is None else parsed.astimezone(tz))


def message_of(record: dict[str, Any]) -> dict[str, Any] | None:
    message = record.get("message")
    if isinstance(message, dict):
        return message
    # pi-subagents transcript rows are plain messages rather than session entries.
    return record if isinstance(record.get("role"), str) else None


def candidate(record: dict[str, Any]) -> bool:
    message = message_of(record)
    if message and message.get("role") == "assistant":
        return True
    return record.get("type") in {"compaction", "branch_summary"}


def record_id(record: dict[str, Any], source: Path, line: int) -> str:
    value = record.get("id")
    if isinstance(value, str) and value:
        return f"entry:{value}"
    # Transcript rows have no Pi entry id. Their source position is their stable owner.
    return f"source:{source}:{line}"


def logical_session(record: dict[str, Any], source: Path) -> tuple[str, str | None]:
    if record.get("type") == "session" and isinstance(record.get("id"), str):
        parent = record.get("parentSession")
        parent_id = session_id(str(parent)) if isinstance(parent, str) else None
        return record["id"], parent_id or (Path(parent).stem if isinstance(parent, str) else None)
    return source.stem, None


def session_id(value: str) -> str | None:
    matches = set(SESSION_ID.findall(value))
    return matches.pop().lower() if len(matches) == 1 else None


def source_parent(source: Path) -> str | None:
    """Read only the session header so an original file wins over its fork."""
    try:
        with source.open(encoding="utf-8") as stream:
            record = json.loads(next(stream))
    except (OSError, StopIteration, json.JSONDecodeError):
        return None
    parent = record.get("parentSession") if isinstance(record, dict) else None
    return str(parent) if isinstance(parent, str) else None


def scan(sessions_dir: Path, since: datetime, until: datetime, tz: ZoneInfo) -> tuple[Totals, dict[str, Session], list[dict[str, str]], list[str]]:
    totals = Totals()
    sessions: dict[str, Session] = {}
    excluded: list[dict[str, str]] = []
    errors: list[str] = []
    seen: dict[str, str] = {}

    if not sessions_dir.is_dir():
        return totals, sessions, excluded, [f"missing sessions directory: {sessions_dir}"]

    # Pi writes copied history only to a file that declares parentSession. Process
    # roots first, so the original source owns a duplicate entry id deterministically.
    sources = list(sessions_dir.rglob("*.jsonl"))
    parents = {source: source_parent(source) for source in sources}
    for source in sorted(sources, key=lambda item: (parents[item] is not None, str(item))):
        source_session = source.stem
        source_parent_id: str | None = None
        try:
            lines = source.read_text(encoding="utf-8").split("\n")
        except OSError as err:
            errors.append(f"unreadable {source}: {err}")
            continue
        for line_number, line in enumerate(lines, 1):
            if not line.strip():
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                errors.append(f"invalid JSON {source}:{line_number}")
                continue
            if not isinstance(record, dict):
                continue
            if record.get("type") == "session":
                source_session, source_parent_id = logical_session(record, source)
                sessions.setdefault(source_session, Session(source_session, str(source), source_parent_id))
                continue
            if not candidate(record):
                continue
            message = message_of(record) or {}
            cost, usage = cost_of(record, message)
            label = f"{source}:{line_number}"
            if cost is None:
                excluded.append({"record": label, "reason": "missing supported cost shape"})
                continue
            when = event_time(record, message, tz)
            if when is None:
                excluded.append({"record": label, "reason": "missing or invalid timestamp"})
                continue
            if not (since <= when < until):
                excluded.append({"record": label, "reason": "outside requested date range"})
                continue
            identity = record_id(record, source, line_number)
            fingerprint = hashlib.sha256(json.dumps(record, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
            if identity in seen:
                if seen[identity] != fingerprint:
                    errors.append(f"conflicting record identity {identity} at {label}")
                else:
                    excluded.append({"record": label, "reason": f"copied record identity {identity}"})
                continue
            seen[identity] = fingerprint
            session = sessions.setdefault(source_session, Session(source_session, str(source), source_parent_id))
            session.totals.add(usage, cost)
            totals.add(usage, cost)
            model = message.get("model") or record.get("model")
            if isinstance(model, str) and model:
                session.models.add(model)
    return totals, sessions, excluded, errors


def legacy_timestamp_total(sessions_dir: Path, since: datetime, until: datetime, tz: ZoneInfo) -> float:
    """The removed Waybar predicate, retained only to explain historical reports."""
    total = 0.0
    for source in sessions_dir.rglob("*.jsonl") if sessions_dir.is_dir() else []:
        started: datetime | None = None
        try:
            lines = source.read_text(encoding="utf-8").split("\n")
        except OSError:
            continue
        for line in lines:
            if not line.strip():
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(record, dict):
                continue
            if record.get("type") == "session" and started is None:
                started = event_time(record, {}, tz)
                continue
            message = record.get("message")
            if record.get("type") != "message" or not isinstance(message, dict) or message.get("role") != "assistant":
                continue
            raw_cost = message.get("usage", {}).get("cost") if isinstance(message.get("usage"), dict) else None
            cost = raw_cost.get("total") if isinstance(raw_cost, dict) else None
            when = event_time(record, message, tz)
            if isinstance(cost, (int, float)) and started is not None and when is not None and started <= when and since <= when < until:
                total += float(cost)
    return total


def ccusage(command: list[str]) -> dict[str, Any] | None:
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True)
        return json.loads(result.stdout)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
        return None


def ccusage_total(payload: dict[str, Any] | None) -> float | None:
    totals = payload.get("totals") if isinstance(payload, dict) else None
    value = totals.get("totalCost") if isinstance(totals, dict) else None
    return float(value) if isinstance(value, (int, float)) else None


def non_pi_totals(since: str, until: str, timezone: str) -> dict[str, float] | None:
    payload = ccusage([
        "bunx", f"ccusage@{CCUSAGE_VERSION}", "--json", "--by-agent", "--sections", "daily,monthly",
        "--since", since, "--until", until, "--timezone", timezone,
    ])
    if not isinstance(payload, dict):
        return None
    totals: dict[str, float] = {}
    for section in ("daily", "monthly"):
        total = 0.0
        rows = payload.get(section)
        if not isinstance(rows, list):
            continue
        for row in rows:
            if not isinstance(row, dict):
                continue
            for agent in row.get("agents", []):
                if isinstance(agent, dict) and agent.get("agent") != "pi" and isinstance(agent.get("totalCost"), (int, float)):
                    total += float(agent["totalCost"])
        totals[section] = total
    return totals


def oak_usage() -> dict[str, Any]:
    state_dir = Path(os.environ.get("OAK_TREE_STATE_DIR", Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "oak-tree"))
    stored: set[str] = set()
    for path in (state_dir / "sessions").glob("*.json") if (state_dir / "sessions").is_dir() else []:
        try:
            session = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError):
            continue
        for value in session.get("agent_session_ids", []):
            if isinstance(value, str):
                canonical = session_id(value) or (value.lower() if SESSION_ID.fullmatch(value) else None)
                if canonical:
                    stored.add(canonical)
    payload = ccusage(["bunx", f"ccusage@{CCUSAGE_VERSION}", "session", "--json"])
    rows = payload.get("session") if isinstance(payload, dict) else []
    attributed = 0.0
    found: set[str] = set()
    if isinstance(rows, list):
        for row in rows:
            if not isinstance(row, dict) or row.get("agent") != "pi":
                continue
            sid = session_id(str(row.get("period", "")))
            cost = row.get("totalCost")
            if sid in stored and isinstance(cost, (int, float)):
                attributed += float(cost)
                found.add(sid)
    return {"attributed_cost_usd": round(attributed, 8), "stored_ids": sorted(stored), "stored_ids_without_ccusage_row": sorted(stored - found)}


def bounds(since: str, until: str, tz: ZoneInfo) -> tuple[datetime, datetime]:
    start = datetime.combine(date.fromisoformat(since), time.min, tz)
    # --until is an inclusive calendar date, so a human can reproduce a whole month.
    end = datetime.combine(date.fromisoformat(until), time.min, tz).replace(day=date.fromisoformat(until).day)
    from datetime import timedelta
    return start, end + timedelta(days=1)


def report(args: argparse.Namespace) -> int:
    tz = ZoneInfo(args.timezone)
    since, until = bounds(args.since, args.until, tz)
    root = Path(args.sessions_dir).expanduser()
    totals, sessions, excluded, errors = scan(root, since, until, tz)
    pi_path = str(root)
    cc_daily = ccusage(["bunx", f"ccusage@{CCUSAGE_VERSION}", "pi", "daily", "--json", "--pi-path", pi_path, "--since", args.since, "--until", args.until, "--timezone", args.timezone])
    cc_monthly = ccusage(["bunx", f"ccusage@{CCUSAGE_VERSION}", "pi", "monthly", "--json", "--pi-path", pi_path, "--since", args.since, "--until", args.until, "--timezone", args.timezone])
    non_pi = non_pi_totals(args.since, args.until, args.timezone)
    legacy = legacy_timestamp_total(root, since, until, tz)
    oak = oak_usage()
    stored = set(oak.pop("stored_ids"))
    linked = sum(session.totals.cost for session in sessions.values() if session.id.lower() in stored)
    unlinked = totals.cost - linked
    oak["canonical_attributed_cost_usd"] = round(linked, 8)
    oak["canonical_unlinked_cost_usd"] = round(unlinked, 8)
    report_data = {
        "ccusage_version": CCUSAGE_VERSION,
        "timezone": args.timezone,
        "range": {"since": args.since, "until": args.until},
        "scanned_roots": [str(root)],
        "canonical_pi": totals.json(),
        "legacy_waybar_timestamp_filter_cost_usd": round(legacy, 8),
        "ccusage_pi": {"daily_cost_usd": ccusage_total(cc_daily), "monthly_cost_usd": ccusage_total(cc_monthly)},
        "waybar": {
            "pi_cost_usd": round(totals.cost, 8),
            "legacy_pi_cost_usd": round(legacy, 8),
            "non_pi_daily_cost_usd": None if non_pi is None else non_pi.get("daily"),
            "non_pi_monthly_cost_usd": None if non_pi is None else non_pi.get("monthly"),
        },
        "oak_tree": oak,
        "sessions": [session.json() for session in sorted(sessions.values(), key=lambda item: item.id)],
        "excluded_records": excluded,
        "errors": errors,
    }
    print(json.dumps(report_data, indent=2, sort_keys=True))
    return 1 if errors else 0


def summary(args: argparse.Namespace) -> int:
    tz = ZoneInfo(args.timezone)
    today = datetime.now(tz).date()
    month_start = today.replace(day=1)
    all_since, all_until = bounds(month_start.isoformat(), today.isoformat(), tz)
    today_since, today_until = bounds(today.isoformat(), today.isoformat(), tz)
    root = Path(args.sessions_dir).expanduser()
    month, _, _, errors = scan(root, all_since, all_until, tz)
    day, _, _, day_errors = scan(root, today_since, today_until, tz)
    if errors or day_errors:
        raise RuntimeError("; ".join(dict.fromkeys(errors + day_errors)))
    print(json.dumps({"today": round(day.cost, 8), "month": round(month.cost, 8), "timezone": args.timezone}))
    return 0


def main() -> int:
    default_sessions = Path(os.environ.get("PI_CODING_AGENT_DIR", Path.home() / ".pi/agent")) / "sessions"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sessions-dir", default=default_sessions)
    parser.add_argument("--timezone", default=os.environ.get("TZ", "Europe/Oslo"))
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("summary")
    report_parser = sub.add_parser("report")
    report_parser.add_argument("--since", required=True)
    report_parser.add_argument("--until", required=True)
    args = parser.parse_args()
    try:
        return summary(args) if args.command == "summary" else report(args)
    except (OSError, RuntimeError, ValueError, ZoneInfoNotFoundError) as err:
        print(f"pi_usage: {err}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    from zoneinfo import ZoneInfoNotFoundError
    raise SystemExit(main())
