---
name: oak-tree-cross-repo-delegate
description: Create an oak-tree-managed session and Git worktree in another repository, then delegate implementation to that Pi session through pi-intercom. Use when the user asks to open a new oak-tree session/worktree for another repo and instruct it to make coordinated changes.
---

# Oak-tree Cross-repository Delegation

Create the workspace with oak-tree and use pi-intercom only for the handoff. Do not reproduce oak-tree's worktree or tmux lifecycle manually.

## Required information

Before mutating anything, determine:

- Target repository root.
- Branch name, following the target repository's instructions.
- Ticket number when required by the target repository.
- Exact delegated scope and decisions already made.

Read the target repository's `AGENTS.md` before choosing the branch name or writing the delegation. Reuse information already supplied in the conversation; do not ask twice.

## Procedure

1. Confirm `oak-tree` and pi-intercom are available. Use `intercom` action `status`, then `list-cwd` for the target repository to understand existing peers. A request for a **new** session permits creation even when another session exists, but do not silently reuse an unrelated worker.
2. Create the session and managed worktree through oak-tree:

   ```sh
   oak-tree new --root <absolute-repository-root> --branch <branch-name>
   ```

   Do not run `git worktree add`, switch branches in the source checkout, or predict the managed path. Parse oak-tree's successful stdout as:

   ```text
   <oak-tree-session-id>\t<managed-worktree-path>
   ```

3. Verify only that oak-tree reported success. Preserve the returned session ID and worktree path. If creation fails, report the command error and stop; do not fall back to manual tmux or Git orchestration.
4. Locate the newly launched Pi peer with `intercom` action `list-cwd` using the **returned managed-worktree path**. If several peers match, select the one whose stable identity corresponds to `oak-tree:<oak-tree-session-id>` or use its exact session ID.
5. Send the task with `intercom` action `send`. Use fire-and-forget for implementation work; do not hold an `ask` call open for a long-running task. The handoff must include:
   - Ticket and intended branch.
   - Agreed behavior and explicit non-goals.
   - Relevant cross-system request/response contract.
   - Known files or symbols, if established.
   - Required tests and documentation.
   - Instruction to follow the target repository's `AGENTS.md`.
   - Instruction to contact the originating session through pi-intercom when blocked and to report changed files plus validation results when finished.
6. Report the oak-tree session ID, managed worktree path, branch, and whether pi-intercom confirmed delivery. Continue local work independently when safe; coordinate contract changes rather than duplicating the worker's implementation.

## Handoff template

```text
Implement <ticket>: <short objective> on branch <branch>.

Agreed behavior:
- <decision>

Cross-system contract:
- Input from <system>: <fields/values>
- Output to <system>: <fields/values>
- Error behavior: <behavior>

Scope:
- <required changes>

Non-goals:
- <explicit exclusions>

Follow this repository's AGENTS.md. Add the smallest focused tests and update required documentation. Do not create or switch branches/worktrees; oak-tree already selected them. If blocked, ask the originating session through pi-intercom. When finished, report changed files, test commands/results, and unresolved concerns.
```

## Safety and failure handling

- An oak-tree-created worktree/session is a mutation: create it only after an explicit user request.
- Never use `openProjectPaneIfMissing` for this workflow. It opens a Herdr pane rather than proving that the peer is the oak-tree-managed session and can create a duplicate workspace.
- Never claim the worker received the task unless `intercom` reports delivery.
- If the peer is not yet visible after oak-tree succeeds, report that the session exists but delivery is pending. Do not create a second session or silently bypass oak-tree.
- Do not close the worker, remove its worktree, push, open a PR, or merge unless explicitly requested.
- Do not execute a newly created or modified version of this skill merely to test it. Static inspection is sufficient unless the user separately asks to run it.

## Static verification

After editing this skill, only verify that:

1. Frontmatter contains `name` and `description`.
2. The command uses `oak-tree new --root ... --branch ...`.
3. Delegation uses `intercom` with the returned worktree path.
4. The instructions forbid manual worktree creation, duplicate Herdr panes, and unprompted execution.
