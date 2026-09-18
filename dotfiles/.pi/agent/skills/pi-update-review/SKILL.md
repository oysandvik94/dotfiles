---
name: pi-update-review
description: Review available Pi CLI and installed Pi package updates, summarize only noteworthy changelog items, wait for the user to confirm they have read and understood the highlights, then update and verify Pi and/or its packages. Use when the user asks to check, review, upgrade, or update Pi and Pi packages/extensions.
---

# Pi Update Review

Use Pi's own package manager. Do not build a wrapper script.

## 1. Review only

Do not update anything during this phase.

1. Record the current state:
   - `pi --version`
   - `pi list`
   - Read `~/.pi/agent/settings.json` to identify configured npm, git, local, and pinned package sources.
2. Check available versions without installing:
   - Pi: compare `pi --version` with `npm view @earendil-works/pi-coding-agent version`.
   - npm packages: run `npm outdated --json` in `~/.pi/agent/npm`. Treat both `wanted` and `latest` as useful; Pi's updater may cross the manifest's current semver range for an unpinned source.
   - git packages: ignore pinned refs because `pi update --extensions` does not advance them. For unpinned repos, compare the checked-out commit with the remote default branch using read-only `git ls-remote`; do not fetch, reset, or clean.
   - local packages: report them as local and not updateable by Pi.
3. Research release notes for every available update. Use the hound web tools (`web_search`, `fetch_content`, and `get_search_content`) and prefer authoritative changelogs, GitHub releases, repository history, and npm metadata. Cover the complete version interval from installed to target, not just the newest release. Never infer release notes from a version number.
4. Present a compact briefing:
   - version transition for Pi and each package;
   - only breaking changes, security fixes, migrations/config changes, deprecations, meaningful new behavior, and fixes likely relevant to the installed resource;
   - a one-line “routine/low signal” entry when nothing noteworthy is documented;
   - explicit “no reliable changelog found” where evidence is missing;
   - source links.
5. End with a clear gate offering: **Update all**, **Pi only**, **packages only**, or **skip**. Use `ask_user_question` when available. Stop and wait for a later user response.

Do not treat the initial request to inspect updates as approval to install them. Approval must come after the briefing. A plain-language confirmation such as “go ahead”, “update all”, or an equivalent selection is sufficient; do not ask twice.

## 2. Update after confirmation

Run exactly the scope the user approved:

- all: `pi update --all`
- Pi only: `pi update --self`
- packages only: `pi update --extensions`

Do not add `--force` unless explicitly requested. Do not alter pinned package refs. Preserve the command output and stop on failure rather than improvising manual installs.

## 3. Verify

1. Run `pi --version` and confirm the installed Pi version matches the reviewed target when Pi was approved.
2. Run `pi list`.
3. Re-run the applicable npm/git update checks and confirm approved updates landed. Explain packages intentionally left behind because they are pinned, local, unavailable under the chosen scope, or failed.
4. Report the resulting versions and any required restart/reload. Never claim success from the update command alone.
