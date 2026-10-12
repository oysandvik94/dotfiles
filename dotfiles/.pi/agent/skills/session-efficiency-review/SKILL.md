---
name: session-efficiency-review
description: Review a completed or current Pi AI session for avoidable token/context usage and reusable improvements. Use when the user asks to review a session, reduce repeated token usage, extract a reusable skill or workflow, improve retrieval/RAG, or move recurring knowledge into documentation, project rules, or memory.
---

# Session Efficiency Review

Review the evidence before proposing machinery. The goal is less repeated context and tool work in future sessions, not a generic list of AI optimizations.

## Input

Accept one of:

- No argument or `current`: use `$PI_SESSION_FILE`.
- A `.jsonl` session path.
- A Pi session ID; resolve it from the current/configured Pi session locations and stop if it is ambiguous.
- An optional task/topic phrase. If the session contains several tasks, scope the review to the relevant user-message span. Ask only when the intended span cannot be inferred.

Do not paste the whole JSONL into model context or reproduce credentials, tokens, cookies, private keys, or unrelated sensitive content in the review.

## Procedure

1. Resolve this skill's directory and run:

   ```bash
   python3 <skill-dir>/scripts/analyze_session.py [session-path-or-id]
   ```

2. The default report follows the active session-tree branch and emits no message bodies. If needed, identify the task from sanitized user-message previews:

   ```bash
   python3 <skill-dir>/scripts/analyze_session.py [session] --user-previews
   ```

3. Rerun metrics for only the selected task span:

   ```bash
   python3 <skill-dir>/scripts/analyze_session.py [session] --from-line 12 --to-line 345
   ```

   Treat user-driven scope changes and necessary investigation as constraints, not automatically as waste.
4. Inspect only evidence lines identified by the scoped report:

   ```bash
   python3 <skill-dir>/scripts/analyze_session.py [session] --from-line 12 --to-line 345 --show 34,56
   ```

   Output is best-effort redacted. Never use `--raw-content` unless the user explicitly requests local raw inspection. Add more lines only when needed to support a finding.
5. Check existing reusable material before recommending anything new:
   - Available skills in the system prompt and `~/.pi/agent/skills/`, `~/.agents/skills/`, and project skill directories.
   - Project `AGENTS.md`, `CLAUDE.md`, and relevant repository docs.
   - Existing prompt workflows and memory only when the recommendation belongs there.
6. Run the reasoning-to-automation classification below. Use the report's reasoning-heavy turns, visible thinking-summary lines, repeated tool sequences, failures, and user corrections as evidence. These are candidate signals, not proof that automation is warranted.
7. Rank at most five concrete improvements. Prefer deletion, narrower commands, bounded output, existing docs, and existing skills over new infrastructure.
8. Do not create or edit skills, prompts, rules, memory, RAG indexes, or docs during a review unless the user explicitly asks for those mutations.

## What to Check

### Session shape

- One long session accumulated unrelated tasks or crossed repositories when a fresh session/subagent would avoid replaying old context.
- Too many assistant turns, granular progress calls, status checks, or retries for the task.
- Compaction happened late or important state survived only in conversation instead of a small task artifact.

### Tool and output efficiency

- Exact repeated calls, repeated reads of the same file, overlapping searches, or duplicated parent/subagent work.
- Broad searches or validation commands returned large irrelevant payloads.
- Known baseline failures were rerun instead of using a narrower check.
- Full files/results were loaded when bounded reads, `findText`, targeted grep, or a summary artifact would suffice.
- Subagents returned large raw reports instead of concise findings with evidence locations.

### Reuse destination

Choose the smallest durable home:

| Pattern | Best home |
|---|---|
| Stable project fact, architecture rule, source of truth | Existing repository docs or `AGENTS.md`/`CLAUDE.md` |
| Repeated deterministic multi-step operation with tools | Skill |
| Repeated small command requiring a pinned model/thinking level | Prompt workflow/subagent profile |
| Large changing corpus requiring semantic lookup across sources | RAG/index |
| Small local corpus already searchable by grep/path | Keep as files; no RAG |
| User preference or cross-session personal convention | Memory |
| One task's evolving decisions | Repository-local plan/decision file |

Do not recommend RAG merely because retrieval occurred. Require a recurring corpus, poor direct-search ergonomics, and a credible refresh/source-of-truth strategy.

### Candidate quality

A reusable extraction should have repeated evidence or a clearly recurring trigger, stable inputs/outputs, meaningful avoided work, and one authoritative implementation location. Reject speculative abstractions and anything already covered by an existing skill or rule.

## Reasoning-to-Automation Classification

Private reasoning may be encrypted or unavailable. Infer conservatively from visible thinking summaries, tool-call sequences, retries, produced artifacts, and user corrections. Never claim access to hidden reasoning.

For each recurring reasoning pattern, identify the smallest **deterministic kernel**: the steps whose inputs, branches, outputs, and success checks can be specified without model judgment. Then classify it:

| Classification | Test | Destination |
|---|---|---|
| Deterministic operation | Finite inputs/branches, objective outcome, stable tool sequence | Script wrapped by a skill |
| Deterministic retrieval | Stable source/query/filter/output shape | Existing search helper or a retrieval skill |
| Rediscovered fact/rule | Reasoning repeatedly establishes the same stable fact | Repository docs or project rules |
| Repeated judgment workflow | Stable rubric/output, but interpretation still varies | Skill or prompt workflow; keep model judgment explicit |
| Corpus retrieval problem | Repeated semantic lookup over a large changing corpus defeats direct search | RAG/index with refresh ownership |
| Irreducible judgment | Novel trade-offs, ambiguous requirements, or context-specific design | Keep model-driven |
| Pure overhead | Progress bookkeeping, duplicated validation, or avoidable retries | Delete or narrow it; do not automate waste |

A proposed deterministic extraction must state:

1. Trigger and required inputs.
2. Deterministic steps and objective success check.
3. Remaining model judgment, if any.
4. Evidence lines showing recurrence or a clearly recurring user need.
5. Why an existing tool, skill, rule, or plain command does not already cover it.

Do not turn an entire task into a skill when only one small loop is deterministic. Extract that loop and leave investigation or architectural judgment outside it.

## Token Interpretation

Separate:

- **Fresh input**: newly supplied prompt/context tokens.
- **Cache read**: reused provider prompt-cache tokens; cheaper than fresh input but still evidence of a large context being processed.
- **Output/reasoning**: generated work.
- **Tool-result characters**: a proxy for context pollution, not a token count.

Do not claim exact future token savings. Give an evidence-backed direction such as low/medium/high and name what would no longer be repeated.

## Output

Use this compact structure:

```markdown
# Session efficiency review

## Verdict
<2-4 sentences: dominant cost and whether reusable extraction is worthwhile>

## Highest-value improvements
1. **<change> — <high/medium/low impact>**
   - Evidence: <session line(s), counts, or task span>
   - Why: <avoidable repeated context/tool work>
   - Implement: <smallest durable change>

## Reasoning that can become deterministic
1. **<pattern> — <classification, impact, confidence>**
   - Evidence: <reasoning/tool/user-correction lines>
   - Deterministic kernel: <inputs, steps, success check>
   - Keep model-driven: <remaining judgment, or none>
   - Home: <existing tool, script+skill, docs/rule, workflow, or RAG>

Use `None found` when no candidate clears the bar.

## Keep as-is
- <necessary work that looked expensive but was justified>

## Not worth building
- <RAG/skill/rule ideas rejected and why>

## Suggested next action
<one concrete action; do not perform it without permission>
```

Mention measurement limitations and infrastructure/tool failures only when they affect a conclusion. Focus on changes that will alter the next similar session.