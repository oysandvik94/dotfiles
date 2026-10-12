#!/usr/bin/env python3
"""Run one verification command without flooding the caller's context."""

from __future__ import annotations

import argparse
import math
import os
import re
import signal
import subprocess
import tempfile
import time
from pathlib import Path

ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
IMPORTANT = re.compile(
    r"(?i)(\berror\b|\bfail(?:ed|ure|ures|ing)?\b|exception|caused by|fatal|"
    r"tests run:|build failure|compilation failure|timeout)"
)
MAX_LINES = 60
MAX_CHARS = 6_000


def group_exists(pid: int) -> bool:
    try:
        os.killpg(pid, 0)
        return True
    except ProcessLookupError:
        return False


def terminate_group(process: subprocess.Popen[str]) -> None:
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        process.wait(timeout=1)
    except subprocess.TimeoutExpired:
        pass
    deadline = time.monotonic() + 4
    while group_exists(process.pid) and time.monotonic() < deadline:
        time.sleep(0.05)
    if group_exists(process.pid):
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    try:
        process.wait(timeout=1)
    except subprocess.TimeoutExpired:
        pass


def diagnostics(text: str) -> tuple[list[str], int]:
    lines = ANSI.sub("", text).splitlines()
    indices = {
        nearby
        for index, line in enumerate(lines)
        if IMPORTANT.search(line)
        for nearby in range(max(0, index - 1), min(len(lines), index + 2))
    }
    selected = [lines[index] for index in sorted(indices)] if indices else lines[-40:]
    deduplicated = list(dict.fromkeys(selected))
    shown: list[str] = []
    size = 0
    for line in deduplicated:
        if len(shown) == MAX_LINES or size + len(line) + 1 > MAX_CHARS:
            break
        shown.append(line)
        size += len(line) + 1
    return shown, len(deduplicated) - len(shown)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--label")
    parser.add_argument("--timeout", type=float)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        parser.error("a command is required after --")
    if args.timeout is not None and (not math.isfinite(args.timeout) or args.timeout <= 0):
        parser.error("--timeout must be a positive finite number")

    label = args.label or Path(command[0]).name
    fd, log_name = tempfile.mkstemp(prefix="quiet-verifier-", suffix=".log")
    os.chmod(log_name, 0o600)
    started = time.monotonic()
    timed_out = False
    interrupted_by: int | None = None

    with os.fdopen(fd, "w", encoding="utf-8", errors="replace") as log:
        try:
            process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            previous_handlers = {}

            def interrupt(signum: int, _frame: object) -> None:
                nonlocal interrupted_by
                interrupted_by = signum
                raise KeyboardInterrupt

            for handled_signal in (signal.SIGINT, signal.SIGTERM):
                previous_handlers[handled_signal] = signal.signal(handled_signal, interrupt)
            try:
                exit_code = process.wait(timeout=args.timeout)
            except subprocess.TimeoutExpired:
                timed_out = True
                terminate_group(process)
                exit_code = 124
                log.write(f"\nTIMEOUT after {args.timeout:g} seconds\n")
            except KeyboardInterrupt:
                terminate_group(process)
                exit_code = 128 + (interrupted_by or signal.SIGINT)
                log.write(f"\nINTERRUPTED by signal {interrupted_by or signal.SIGINT}\n")
            finally:
                for handled_signal, previous_handler in previous_handlers.items():
                    signal.signal(handled_signal, previous_handler)
        except OSError as error:
            exit_code = 127
            log.write(f"ERROR: {error}\n")

    if exit_code < 0:
        interrupted_by = -exit_code
        exit_code = 128 + interrupted_by
    elapsed = time.monotonic() - started
    if exit_code == 0:
        Path(log_name).unlink(missing_ok=True)
        print(f"PASS {label} ({elapsed:.1f}s)")
        return 0

    output = Path(log_name).read_text(encoding="utf-8", errors="replace")
    shown, omitted = diagnostics(output)
    reason = "TIMEOUT" if timed_out else (f"signal {interrupted_by}" if interrupted_by else f"exit {exit_code}")
    print(f"FAIL {label} ({reason}, {elapsed:.1f}s)")
    for line in shown:
        print(line)
    if omitted:
        print(f"… {omitted} relevant lines omitted")
    print(f"Full output: {log_name}")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
