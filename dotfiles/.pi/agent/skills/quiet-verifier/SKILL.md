---
name: quiet-verifier
description: Run builds, tests, linters, and checkstyle with success-only summaries and bounded diagnostics on failure. Use when verification commands are noisy, especially Maven commands whose warnings or baseline violations would otherwise flood the session.
---

# Quiet Verifier

Run the smallest verification command that proves the change. Do not automate a broad build when one focused test is enough.

## Run

Resolve this skill directory, then wrap one command:

```bash
python3 <skill-dir>/scripts/quiet_verify.py --label '<short check>' -- <command> [args...]
```

The helper prints one `PASS` line and deletes its log on success. On failure it prints bounded error context, preserves the complete private log, and returns the command's exit code.

For Maven, call RTK explicitly so Maven-aware filtering happens before the verifier captures it:

```bash
python3 <skill-dir>/scripts/quiet_verify.py --label 'ModuleTest' -- \
  rtk mvn -pl module test -Dtest=ModuleTest
```

Use `rtk mvn`, not a raw `./mvnw`, for checkstyle too; RTK's automatic rewrite does not recognize every Maven plugin goal.

## Failure handling

1. Read the bounded failure output first.
2. If more evidence is needed, search or read a bounded slice of the retained log; never print the whole file by default.
3. Remove the retained log after resolving or reporting the failure.
4. If the failure is an established unrelated baseline problem, do not rerun the same broad command. Verify changed files or focused tests instead and report the limitation.

Use `--timeout <seconds>` for checks with an explicit time bound. The helper terminates the command's process group on timeout.

Never wrap commands likely to print credentials or payload data. This skill is for local build and test output.

## Verification

```bash
python3 <skill-dir>/scripts/test_quiet_verify.py
```
