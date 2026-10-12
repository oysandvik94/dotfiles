---
name: secana-authz-wiki
description: Persistent context for the secana-nextgen SAA authorization redesign in think-thank (ADR saa-rest-api-authorization-draft-2). Use whenever working in secana-nextgen on authorization, roles, user groups, bank groups, access management, or when asked about the authz tasks, decisions, open questions, or creating Jira tickets for them.
---

# SAA authorization workspace

**Implementation source of truth: Jira epic SNG-11760 and its child tasks.** think-thank project **SAA authorization (secana-nextgen)** keeps linked context, open questions and history.
Project UUID: `a029a12b-047d-4a4d-9b33-53f0898c65f3`.

First read `/home/sandvoys/.pi/agent/skills/think-thank/SKILL.md` and follow its REST workflow and safe-write rules. Before writing, read its `references/api.md` (resolve relative to that skill's directory).

## Get context

1. Discover the API and list projects as the think-thank skill requires. Use the UUID above; if missing, ask rather than creating a replacement.
2. Read the project snapshot for task context, counts and pending follow-ups. Get the full project for its summary and ADR. Read T1 (`2ae39cd8-f528-4179-9092-267d01231fba`) background notes for the historical project handoff and mappings. Get relevant item details for bodies and links. Follow pagination when completeness matters.
3. Before authz work, read the relevant task, its connected questions and confirmed decisions. For investigation, also list questions needing action. Preserve proposals as proposals and do not invent personal commitments.

The project description is a short plain-text summary, limited to 500 characters. Historical handoffs belong in background notes, not the description. Jira defines current implementation scope. Existing decisions and imported ADR choices do not override that scope.

## Original labels and archive

The old wiki's T/Q/D/F labels are historical references inside imported Markdown. think-thank assigns its own project-scoped codes: consult the historical mapping in T1 background notes and use item UUIDs for API operations. Do not assume an old label identifies the same current code.

`~/jobbwiki/secana-authz/` is a **legacy archive**, not the active workspace. Do not update its tasks, questions, decisions, follow-ups, STATUS or generated portal, and do not run `build.py` for ongoing work. Migration journal, UUID mapping and verification artifacts are in `~/jobbwiki/secana-authz/think-thank-migration/`. Never rerun the import as a normal workspace operation.

Repo ADR: `~/dev/jobb/secana-nextgen/docs/adr/authorization/saa-rest-api-authorization-draft-2.md`. Do not change it or the project's ADR text unless asked. If comparing them, report discrepancies rather than silently overwriting either.

## Refine tasks one at a time

1. Read the task, connected questions/decisions and cited ADR sections.
2. Research actual code. Record verified findings in the task's Implementation notes with concrete paths, classes, tables and gotchas. Say what was not checked.
3. Write the Goal as an outcome and acceptance criteria as testable behavior. Research steps belong in notes, not acceptance criteria.
4. Put unverified assumptions in Uncertainties. Real open choices belong in QUESTION items with options, trade-offs and a concrete next step; link affected tasks using RELATES_TO. Keep personal investigation reminders as FOLLOWUP items, separate from implementation tasks, only when requested or agreed.
5. Show proposals and open choices to the user. Only actual user confirmation permits a DECISION; use the question decision action to record and resolve atomically. Update affected criteria after confirmation. Keep historical resolution links when reopening.
6. Update current item status, Jira reference and task dependencies through the API; reread after changes. Keep the project description as a plain-text summary of at most 500 characters. Store handoffs and historical migration notes in item background notes.

## Jira readiness

A task is ready when its notes name concrete implementation locations and no open question blocks it. Draft from Goal, Acceptance criteria and Implementation notes. Use the securitysolutions-jira skill for ticket creation, only when asked; then update the task's `jira` field through think-thank.

## Working style

- Say what you are about to do before each step; keep steps short and separate.
- Separate confirmed from proposed. Never record an email, reviewer finding or your own suggestion as a confirmed decision. Attribute statements accurately; say when authorship is unclear.
- Explain in plain language and distinguish verified findings from assumptions.
- Do not run tests or launch reviewer/plan subagents unless asked (see global AGENTS.md).
- If think-thank is unavailable, report it. Do not fall back to editing the archive or database; start the server only when requested.
