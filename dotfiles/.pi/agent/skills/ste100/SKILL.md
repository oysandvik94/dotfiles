---
name: ste100
description: Draft, rewrite, or check text using ASD-STE100-inspired Simplified Technical English. Use when the user says "use STE100", "use STE", "simplified technical English", "aviation manual language", or requests this style for Jira tasks, think-thank items, documentation, or instructions. Check the actual text before sending or saving it, not only the chat reply.
---

# Simplified Technical English

Write clear technical English. Keep the meaning, remove unnecessary words, and check the result before delivery.

## Scope and limits

- Apply this skill to the requested text. Do not enable a permanent writing mode.
- Use it alongside the Jira, think-thank, or documentation skill that controls the actual operation.
- This skill applies selected STE-derived rules. It does not include the official specification or approved-word dictionary.
- Do not call the result certified or fully ASD-STE100 compliant. If formal compliance is required, ask for the applicable specification and approved terminology before claiming verification.
- Do not install plugins, change application behavior, or create a ticket merely because this skill was invoked. Follow the user's requested operation and its approval rules.

## Writing rules

1. Use one instruction per sentence. Start an instruction with a direct verb: "Select the bank."
2. Use no more than 20 words per instruction sentence. Aim for no more than 25 words per descriptive sentence.
3. Use short paragraphs. Keep each paragraph on one topic, with no more than six sentences.
4. Prefer active voice and name the actor when it matters. Do not invent an actor when the source does not identify one.
5. Use simple tenses where they preserve the meaning: "The test checks access," not "The test is checking access."
6. Use one term for one concept. Keep technical names, identifiers, permission codes, headers, commands and API fields unchanged.
7. Use common verbs: "use", "start", "check", "change", "stop" and "show". Replace ornate wording and vague noun stacks.
8. Avoid contractions and semicolons in authored prose. Preserve exact quotations, code and external text when they must remain unchanged.
9. State conditions before the action: "If the bank is disabled, reject the request."
10. Remove filler, repeated explanations and promotional words such as "seamless" or "robust" unless they have a precise technical meaning.

Never remove a safety warning, denial condition, exception, dependency or required acceptance criterion to meet a length target.
Keep "must", "may", "must not", negation, quantities and timing accurate. Do not turn a proposal into a confirmed requirement.

## Tasks and tickets

Use a short action title and these sections unless the destination requires another format:

- **Goal:** the outcome in one or two sentences.
- **Acceptance criteria:** short bullets describing observable behavior.
- **Notes:** only essential implementation locations, dependencies and open choices.

Aim for 150–250 words for a normal task, not counting its title. Use less for a simple task.
Use more when required details cannot fit safely. Do not move requirements out of the task without permission.
Avoid a large scenario table when short bullets convey the same information.
Preserve required user-story formats, Jira fields and existing task scope.

## Draft, check, deliver

1. Read the requested source and destination requirements. Identify terms and conditions that must stay unchanged.
2. Draft or rewrite the text using the rules above.
3. Check the actual deliverable, including the title, body and acceptance criteria. For API writes, inspect the text fields in the final payload before submission.
4. Check sentence length, terminology, actor/action, conditions, negation and scope. Split long sentences without changing their logical relationship.
5. Compare with the source. Restore any lost requirement, warning or uncertainty. Do not add unsupported facts.
6. Correct remaining wording problems before sending or saving. If an installed STE linter is available, use it on the draft when appropriate; do not install one automatically.
7. Follow the destination skill's safe-write workflow. Reread saved text before reporting success. Return the requested text or a short update, not the internal checklist.

These are model-guided checks, not a deterministic compliance gate. Do not report a linter pass unless a linter actually ran.

## Example

Before: "Implement a comprehensive permission verification strategy to ensure unauthorized cross-bank data access is prevented."

After: "Test that users cannot read or change data for banks outside their allowed scope."

## References

Design inspiration, not normative replacements for ASD-STE100:
- https://www.asd-ste100.org/
- https://github.com/ctotheameron/agent-ste
- https://github.com/jyooi/agent-simple-english
