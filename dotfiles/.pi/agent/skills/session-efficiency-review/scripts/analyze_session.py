#!/usr/bin/env python3
"""Produce a compact, content-light report for a Pi JSONL session."""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import os
import re
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit, urlunsplit

SENSITIVE_KEYS = ("password", "secret", "token", "authorization", "cookie", "apikey", "api_key")
SENSITIVE_PATTERNS = (
    (re.compile(r"-----BEGIN [^-]*PRIVATE KEY-----.*?-----END [^-]*PRIVATE KEY-----", re.I | re.S), "[REDACTED PRIVATE KEY]"),
    (re.compile(r"\bBearer\s+[^\s\"']+", re.I), "Bearer [REDACTED]"),
    (re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b"), "[REDACTED JWT]"),
    (re.compile(r'(?i)("(?:password|secret|token|authorization|cookie|api[_-]?key)"\s*:\s*)"[^"]*"'), r'\1"[REDACTED]"'),
    (re.compile(r"(?i)('(?:password|secret|token|authorization|cookie|api[_-]?key)'\s*:\s*)'[^']*'"), r"\1'[REDACTED]'"),
    (re.compile(r"(?i)\b(password|secret|token|authorization|cookie|api[_-]?key)\b(\s*[:=]\s*)(?:\"[^\"]*\"|'[^']*'|[^\s,;]+)"), r"\1\2[REDACTED]"),
)


def sanitize(text: str) -> str:
    for pattern, replacement in SENSITIVE_PATTERNS:
        text = pattern.sub(replacement, text)
    return text


def configured_session_dir() -> Path | None:
    agent_dir = Path(os.environ.get("PI_CODING_AGENT_DIR", Path.home() / ".pi" / "agent")).expanduser()
    setting = None
    global_settings = agent_dir / "settings.json"
    if global_settings.is_file():
        try:
            setting = json.loads(global_settings.read_text()).get("sessionDir")
        except (json.JSONDecodeError, OSError):
            pass
    for parent in (Path.cwd(), *Path.cwd().parents):
        project_settings = parent / ".pi" / "settings.json"
        if not project_settings.is_file():
            continue
        try:
            setting = json.loads(project_settings.read_text()).get("sessionDir", setting)
        except (json.JSONDecodeError, OSError):
            pass
        break
    if not setting:
        return None
    path = Path(setting).expanduser()
    return path if path.is_absolute() else Path.cwd() / path


def session_roots() -> list[Path]:
    roots = []
    current_file = os.environ.get("PI_SESSION_FILE")
    if current_file:
        current_path = Path(current_file).expanduser()
        if len(current_path.parents) > 1:
            roots.append(current_path.parent.parent)
    if configured := os.environ.get("PI_CODING_AGENT_SESSION_DIR"):
        roots.append(Path(configured).expanduser())
    if configured := configured_session_dir():
        roots.append(configured)
    agent_dir = Path(os.environ.get("PI_CODING_AGENT_DIR", Path.home() / ".pi" / "agent")).expanduser()
    roots.append(agent_dir / "sessions")
    return list(dict.fromkeys(path.resolve() for path in roots))


def resolve_session(value: str | None) -> Path:
    if not value or value == "current":
        value = os.environ.get("PI_SESSION_FILE")
        if not value:
            raise SystemExit("No session supplied and PI_SESSION_FILE is unset")

    path = Path(value).expanduser()
    if path.is_file():
        return path.resolve()

    matches = {
        match.resolve()
        for root in session_roots()
        if root.is_dir()
        for match in root.glob(f"**/*{value}*.jsonl")
    }
    if len(matches) != 1:
        detail = "none" if not matches else "\n".join(str(item) for item in sorted(matches)[:10])
        raise SystemExit(f"Session ID/path must resolve uniquely; matches: {detail}")
    return matches.pop()


def text_content(message: dict[str, Any]) -> str:
    content = message.get("content", "")
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    return "\n".join(
        part.get("text", "")
        for part in content
        if isinstance(part, dict) and part.get("type") == "text"
    )


def preview(text: str, limit: int = 180, raw: bool = False) -> str:
    if not raw:
        text = sanitize(text)
    compact = " ".join(text.split())
    return compact[:limit] + ("…" if len(compact) > limit else "")


def redact(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            key: "[REDACTED]" if any(part in key.lower() for part in SENSITIVE_KEYS) else redact(item)
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [redact(item) for item in value]
    return value


def format_args(arguments: Any, limit: int = 1000, raw: bool = False) -> str:
    value = arguments if raw else redact(arguments)
    text = json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    return preview(text, limit, raw=raw)


def load(path: Path) -> list[dict[str, Any]]:
    records = []
    with path.open(encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, 1):
            try:
                record = json.loads(line)
            except json.JSONDecodeError as error:
                raise SystemExit(f"Invalid JSON on line {line_number}: {error}") from error
            record["_line"] = line_number
            records.append(record)
    return records


def active_branch(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_id = {
        record["id"]: record
        for record in records
        if record.get("id") and record.get("type") != "session"
    }
    leaf = next(
        (record for record in reversed(records) if record.get("id") and record.get("type") != "session"),
        None,
    )
    if not leaf:
        return records
    branch_ids = set()
    current = leaf
    while current and current.get("id") not in branch_ids:
        branch_ids.add(current["id"])
        current = by_id.get(current.get("parentId"))
    return [
        record for record in records
        if record.get("type") == "session" or not record.get("id") or record["id"] in branch_ids
    ]


def scoped(records: list[dict[str, Any]], start: int | None, end: int | None) -> list[dict[str, Any]]:
    return [
        record for record in records
        if (start is None or record["_line"] >= start) and (end is None or record["_line"] <= end)
    ]


def safe_url(value: str) -> str:
    try:
        parsed = urlsplit(value)
        host = parsed.hostname or ""
        port = f":{parsed.port}" if parsed.port else ""
        return urlunsplit((parsed.scheme, host + port, parsed.path, "", ""))
    except ValueError:
        return "<invalid URL>"


def fingerprint(label: str, value: str) -> str:
    digest = hashlib.sha256(value.encode()).hexdigest()[:10]
    return f"{label} ({len(value)} chars, sha256:{digest})"


def call_label(name: str, arguments: Any) -> str:
    if not isinstance(arguments, dict):
        return "non-object arguments"
    if path := arguments.get("path"):
        return f"path={path}"
    if url := arguments.get("url"):
        return f"url={safe_url(str(url))}"
    if tool := arguments.get("tool"):
        return f"operation={tool}"
    if action := arguments.get("action"):
        return f"action={action}"
    if command := arguments.get("command"):
        return fingerprint("command", str(command))
    if query := arguments.get("query"):
        return fingerprint("query", str(query))
    if pattern := arguments.get("pattern"):
        return fingerprint("pattern", str(pattern))
    return "keys=" + ",".join(sorted(arguments))


def operation_label(name: str, arguments: Any) -> str:
    if not isinstance(arguments, dict):
        return name
    if name == "bash":
        command = str(arguments.get("command", ""))
        for marker, family in (
            ("./mvnw", "maven"),
            ("git ", "git"),
            ("gh ", "github"),
            ("oc ", "openshift"),
            ("python", "python"),
        ):
            if marker in command:
                return f"bash:{family}"
        return "bash:shell"
    if operation := arguments.get("tool"):
        return f"{name}:{operation}"
    if action := arguments.get("action"):
        return f"{name}:{action}"
    if name == "Agent" and (agent_type := arguments.get("subagent_type")):
        return f"Agent:{agent_type}"
    return name


def repeated_sequences(segments: list[list[tuple[str, int]]]) -> list[tuple[int, tuple[str, ...], list[tuple[int, int]]]]:
    hits: dict[tuple[str, ...], list[tuple[int, int]]] = collections.defaultdict(list)
    for segment in segments:
        for size in range(2, 5):
            for start in range(len(segment) - size + 1):
                window = segment[start:start + size]
                sequence = tuple(label for label, _ in window)
                if len(set(sequence)) == 1 or set(sequence) <= {"read", "ffgrep", "fffind"}:
                    continue
                hits[sequence].append((window[0][1], window[-1][1]))
    candidates = [(len(lines), sequence, lines) for sequence, lines in hits.items() if len(lines) > 1]
    return sorted(
        candidates,
        key=lambda item: (item[0] * len(item[1]) + 3 * sum(":" in label for label in item[1]), item[0], item[1]),
        reverse=True,
    )


def show_lines(records: list[dict[str, Any]], requested: set[int], max_chars: int, raw: bool) -> None:
    by_line = {record["_line"]: record for record in records}
    for line_number in sorted(requested):
        record = by_line.get(line_number)
        if not record:
            print(f"## Line {line_number}\nMissing\n")
            continue
        print(f"## Line {line_number} — {record.get('type')} — {record.get('timestamp', '')}")
        if record.get("type") != "message":
            clean = {key: value for key, value in record.items() if key not in {"_line", "details", "summary"}}
            print(preview(json.dumps(clean, ensure_ascii=False), max_chars, raw), "\n")
            continue

        message = record.get("message", {})
        role = message.get("role", "unknown")
        print(f"Role: {role}")
        usage = message.get("usage")
        if usage:
            print("Usage:", json.dumps(usage, sort_keys=True))
        rendered = []
        if role in {"user", "toolResult"}:
            rendered.append(text_content(message))
        else:
            content = message.get("content", [])
            if isinstance(content, str):
                rendered.append(content)
            elif isinstance(content, list):
                for part in content:
                    if not isinstance(part, dict):
                        continue
                    if part.get("type") == "text":
                        rendered.append(part.get("text", ""))
                    elif part.get("type") == "toolCall":
                        rendered.append(f"TOOL {part.get('name')}: {format_args(part.get('arguments', {}), raw=raw)}")
                    elif part.get("type") == "thinking" and part.get("thinking"):
                        rendered.append(f"THINKING SUMMARY: {part['thinking']}")
        body = "\n".join(rendered)
        if not raw:
            body = sanitize(body)
        print(body[:max_chars] + ("\n…[truncated]" if len(body) > max_chars else ""), "\n")


def add_usage(totals: collections.Counter[str], usage: dict[str, Any]) -> None:
    for key in ("input", "output", "cacheRead", "cacheWrite", "reasoning", "totalTokens"):
        totals[key] += usage.get(key, 0) or 0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("session", nargs="?", help="JSONL path, session ID, or 'current'")
    parser.add_argument("--show", help="Comma-separated JSONL line numbers")
    parser.add_argument("--user-previews", action="store_true", help="Include sanitized user-message previews")
    parser.add_argument("--raw-content", action="store_true", help="Disable best-effort redaction for explicit local inspection")
    parser.add_argument("--from-line", type=int, help="Start of task span, inclusive")
    parser.add_argument("--to-line", type=int, help="End of task span, inclusive")
    parser.add_argument("--all-branches", action="store_true", help="Include abandoned session-tree branches")
    parser.add_argument("--max-chars", type=int, default=4000)
    args = parser.parse_args()

    path = resolve_session(args.session)
    all_records = load(path)
    branch_records = all_records if args.all_branches else active_branch(all_records)
    records = scoped(branch_records, args.from_line, args.to_line)
    if args.show:
        requested = {int(value) for value in args.show.split(",")}
        show_lines(records, requested, args.max_chars, args.raw_content)
        return

    roles: collections.Counter[str] = collections.Counter()
    tools: collections.Counter[str] = collections.Counter()
    exact_calls: dict[tuple[str, str], list[int]] = collections.defaultdict(list)
    call_labels: dict[tuple[str, str], str] = {}
    targets: dict[tuple[str, str], list[int]] = collections.defaultdict(list)
    result_sizes: list[tuple[int, int, str, bool]] = []
    failed_results: list[tuple[int, str, int]] = []
    costly_turns: list[tuple[int, int, int, int, int, str]] = []
    thinking_summaries: list[tuple[int, int, int]] = []
    tool_segments: list[list[tuple[str, int]]] = [[]]
    user_messages: list[tuple[int, str, int, str]] = []
    compactions: list[tuple[int, str, Any]] = []
    totals: collections.Counter[str] = collections.Counter()
    target_keys = ("path", "url", "query", "pattern", "tool", "agent_id")

    for record in records:
        line_number = record["_line"]
        if record.get("type") == "compaction":
            compactions.append((line_number, record.get("timestamp", ""), record.get("tokensBefore")))
        if record.get("type") in {"compaction", "branch_summary"} and isinstance(record.get("usage"), dict):
            add_usage(totals, record["usage"])
        if record.get("type") != "message":
            continue

        message = record.get("message", {})
        role = message.get("role", "unknown")
        roles[role] += 1

        if role == "user":
            body = text_content(message)
            user_messages.append((line_number, record.get("timestamp", ""), len(body), preview(body) if args.user_previews else ""))
            if tool_segments[-1]:
                tool_segments.append([])
        elif role == "assistant":
            usage = message.get("usage", {})
            add_usage(totals, usage)
            called = []
            content = message.get("content", [])
            if not isinstance(content, list):
                content = []
            for part in content:
                if not isinstance(part, dict):
                    continue
                if part.get("type") == "thinking" and part.get("thinking"):
                    thinking_summaries.append((line_number, len(part["thinking"]), usage.get("reasoning", 0) or 0))
                    continue
                if part.get("type") != "toolCall":
                    continue
                name = part.get("name", "unknown")
                arguments = part.get("arguments", {})
                called.append(name)
                tools[name] += 1
                tool_segments[-1].append((operation_label(name, arguments), line_number))
                signature = json.dumps(arguments, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
                key = (name, signature)
                exact_calls[key].append(line_number)
                call_labels[key] = call_label(name, arguments)
                if isinstance(arguments, dict):
                    for target_key in target_keys:
                        value = arguments.get(target_key)
                        if isinstance(value, (str, int, float)) and str(value):
                            targets[(f"{name}.{target_key}", str(value))].append(line_number)
                            break
            costly_turns.append((
                usage.get("input", 0) or 0,
                usage.get("cacheRead", 0) or 0,
                usage.get("output", 0) or 0,
                usage.get("reasoning", 0) or 0,
                line_number,
                ",".join(called) or "none",
            ))
        elif role == "toolResult":
            body = text_content(message)
            name = message.get("toolName", "unknown")
            is_error = bool(message.get("isError"))
            result_sizes.append((len(body), line_number, name, is_error))
            if is_error:
                failed_results.append((line_number, name, len(body)))

    stat = path.stat()
    scope_text = f"L{args.from_line or 1}–L{args.to_line or len(all_records)}"
    print("# Pi session metrics\n")
    print(f"- File: `{path}`")
    print(f"- JSONL: {len(all_records)} physical lines, {stat.st_size:,} bytes")
    print(f"- Included: {len(records)} records on {'all branches' if args.all_branches else 'active branch'}, scope {scope_text}")
    if not args.all_branches:
        print(f"- Excluded off-branch records: {len(all_records) - len(branch_records)}")
    print(f"- Messages: {roles['user']} user, {roles['assistant']} assistant, {roles['toolResult']} tool results")
    print(f"- Compactions: {len(compactions)}")
    print(f"- Tool calls: {sum(tools.values())}; failed results: {len(failed_results)}")
    print(f"- Fresh input: {totals['input']:,}; cache read: {totals['cacheRead']:,}")
    print(f"- Output: {totals['output']:,}; reasoning: {totals['reasoning']:,}; reported total: {totals['totalTokens']:,}")

    print("\n## Tool calls\n")
    for name, count in tools.most_common():
        print(f"- {name}: {count}")

    print("\n## User-message index\n")
    for line_number, timestamp, size, body in user_messages:
        suffix = f": {body}" if body else ""
        print(f"- L{line_number} {timestamp}, {size:,} chars{suffix}")

    print("\n## Highest fresh-input turns\n")
    for fresh, cached, output, reasoning, line_number, called in sorted(costly_turns, reverse=True)[:10]:
        print(f"- L{line_number}: fresh={fresh:,}, cache={cached:,}, output={output:,}, reasoning={reasoning:,}, tools={called}")

    print("\n## Reasoning-heavy turns\n")
    for fresh, cached, output, reasoning, line_number, called in sorted(
        costly_turns, key=lambda item: (item[3], item[2]), reverse=True
    )[:10]:
        print(f"- L{line_number}: reasoning={reasoning:,}, output={output:,}, fresh={fresh:,}, cache={cached:,}, tools={called}")

    print("\n## Visible thinking summaries\n")
    if thinking_summaries:
        for line_number, size, reasoning in sorted(thinking_summaries, key=lambda item: (item[2], item[1]), reverse=True)[:12]:
            print(f"- L{line_number}: {size:,} chars, reasoning={reasoning:,}")
    else:
        print("- None")

    print("\n## Repeated tool-sequence candidates\n")
    sequences = repeated_sequences(tool_segments)
    if sequences:
        for count, sequence, occurrences in sequences[:12]:
            evidence = ",".join(
                f"L{start}" if start == end else f"L{start}–L{end}"
                for start, end in occurrences
            )
            print(f"- {count}× {' → '.join(sequence)} at {evidence}")
    else:
        print("- None")

    print("\n## Largest tool results\n")
    for size, line_number, name, is_error in sorted(result_sizes, reverse=True)[:12]:
        print(f"- L{line_number}: {name}, {size:,} chars" + (", ERROR" if is_error else ""))

    repeats = [(len(lines), key, lines) for key, lines in exact_calls.items() if len(lines) > 1]
    print("\n## Exact repeated calls\n")
    if repeats:
        for count, key, lines in sorted(repeats, reverse=True)[:12]:
            print(f"- {count}× {key[0]} at {','.join('L' + str(line) for line in lines)}: {call_labels[key]}")
    else:
        print("- None")

    repeated_targets = [(len(lines), key, lines) for key, lines in targets.items() if len(lines) > 1]
    print("\n## Repeated targets\n")
    if repeated_targets:
        for count, (kind, value), lines in sorted(repeated_targets, reverse=True)[:15]:
            if kind.endswith(".url"):
                label = safe_url(value)
            elif kind.endswith((".query", ".pattern")):
                label = fingerprint(kind.rsplit(".", 1)[1], value)
            else:
                label = sanitize(value)
            evidence = ",".join("L" + str(line) for line in lines)
            print(f"- {count}× {kind} at {evidence}: {label}")
    else:
        print("- None")

    print("\n## Failed tool results\n")
    if failed_results:
        for line_number, name, size in failed_results[:15]:
            print(f"- L{line_number}: {name}, {size:,} chars")
    else:
        print("- None")

    print("\n## Compactions\n")
    if compactions:
        for line_number, timestamp, tokens_before in compactions:
            detail = f", tokensBefore={tokens_before:,}" if isinstance(tokens_before, int) else ""
            print(f"- L{line_number} {timestamp}{detail}")
    else:
        print("- None")


if __name__ == "__main__":
    main()
