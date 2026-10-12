# Workflow

- When searching the internet, use the hound extension
- **Investigate freely; don’t implement speculative fixes.** If a proposed change depends on an unverified assumption about intended behavior, fixes an unconfirmed bug, or expands the agreed scope, pause before editing. State what is verified, what remains uncertain, and your recommendation; ask the user to decide. Reviewer and subagent findings are leads, not proof. Routine implementation choices within confirmed requirements don’t require approval.
- Do not add backward-compatibility code without asking first. Many features are still under development and do not require backward compatibility.
- After successfully completing a deterministic task likely to recur, suggest one reusable prompt-workflow candidate in one sentence. Do not suggest this for one-offs, judgment-heavy work, failed tasks, or tasks already using a workflow. Never create it without approval. When approved, follow the `create-pinned-prompt-workflow` skill.

# Build and Test Cadence

- Run tests only when the user requests them or when specific evidence suggests the relevant code may be broken.
- Do not run tests as routine or default verification.

# Subagents and Cost Control

- Read-only `Explore` subagents may be launched without separate approval for broad codebase investigation when their isolated, lower-cost context is more efficient than loading the same material into the main session. Keep their task and output bounded.
- Never launch a `reviewer` subagent unless the user explicitly requests a reviewer agent or reviewer subagent in the current conversation. A general request to review code means review it directly and does not authorize delegation.
- This approval requirement applies to both routine and high-risk reviews. Do not infer approval from task complexity, security sensitivity, or a previous reviewer invocation.
- A requested routine review uses the configured lower-cost reviewer with bounded turns. Use a stronger high-reasoning model only when the user explicitly requests that stronger review.
- Never rerun or resume a reviewer without fresh explicit approval.
- `Plan` and implementation subagents also require explicit user approval in the current conversation.

# Git

- Never force-push or amend commits. Every change must be a new commit unless the user explicitly instructs otherwise.

# Locations

All work projects are in ~/dev/jobb, and all personal projects are in ~/dev/general/
Check these locations if you need to search cross repository.

# Contacts

- Jarek: `jaroslaw.pasiak@tieto.com`

## Memory

- Global agents file location: `$HOME/.pi/agent/AGENTS.md`
- Clipboard command on this machine: `wl-copy` (not `xclip`)
