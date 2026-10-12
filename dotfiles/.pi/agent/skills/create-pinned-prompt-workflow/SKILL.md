---
name: "create-pinned-prompt-workflow"
description: "Create reusable Pi prompt workflows backed by subagents pinned to a model and thinking level"
version: 2
---

## When to Use
Use when the user wants a reusable task exposed through `/workflow-picker`, with a pinned model and thinking level. For a one-off task, use `/workflow-picker oneshot <task>` instead; do not create files.

## Procedure
1. Read the installed `@tintinweb/pi-subagents` custom-agent documentation and an existing agent file before changing configuration.
2. Collect missing requirements: workflow slug, task, model, thinking level, minimum tools, and allowed side effects. Workflows always use fresh conversation context, with project instructions inherited.
3. Check `~/.pi/agent/agents/`, project `.pi/agents/`, and `~/.pi/agent/prompts/` for collisions. Ask before replacing an existing workflow. `oneshot` is reserved by the picker.
4. Reuse an existing agent when its model, thinking, tools, and instructions fit. Otherwise write `~/.pi/agent/agents/<slug>.md` using the installed plugin's frontmatter. Pin `model: provider/model-id` and `thinking:`; use `prompt_mode: append` to retain project instructions. Grant only the required tools and spell out side-effect limits.
5. Write `~/.pi/agent/prompts/<slug>.md` with a concise `description` and `subagent: <agent-name>`. Keep task instructions in one place, and use `$@` or `$ARGUMENTS` for additional user instructions. These are the picker's supported placeholders.
6. Read both files back. Do not execute the workflow unless separately requested.
7. Report paths, model/thinking level, and `/workflow-picker <slug>`. Alt+P also lists saved workflows.

## Boundaries
- The picker uses the plugin's event-bus spawn API, not a main-model routing prompt.
- It never switches the main session's model or copies its conversation into the child.
- Results are consumed synchronously to suppress the plugin's main-model completion turn. A short result appears in a UI widget; the full result is available in `/agents`.
- Each agent must authorize side effects explicitly. Bash provides git and gh; creating a PR must be requested by the task.
- Do not add routing skills, compatibility aliases, or extra configuration.

## Verification
Read back the agent's model, thinking level, tools, and side-effect limits. Confirm the prompt names that agent and that the final response gives `/workflow-picker <slug>`. Do not run it as verification.
