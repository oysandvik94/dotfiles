---
name: jira-qa-instructions
description: Add, draft, or shorten a Jira QA testing comment. Use when the user asks to add QA instructions, explain how to test a ticket, or replace an overly detailed testing comment with a simple step-by-step checklist.
---

# Jira QA Instructions

Write a practical comment for a tester, not a test strategy or implementation report.

## Gather only what is needed

- Use the issue key and confirmed behavior from the current task. Ask for the issue key only if missing or ambiguous.
- If context is insufficient, use `atlassian_read` to get the issue summary and description, and inspect only the relevant code or documentation.
- Do not invent expected behavior, test results, endpoints, or setup requirements. If an important expected outcome is uncertain, investigate read-only or ask before publishing.
- This skill works across Jira projects; do not assume an eSign endpoint or SECURITYSOLUTIONS ticket.

## Comment format

Default to English unless requested otherwise. Aim for about 100–180 words:

1. Start with one short sentence explaining what the feature does. Include the endpoint or UI action when necessary.
2. Add a numbered list, usually 3–6 steps. Each step states an action and its expected observable result.
3. Start with the successful case, then cover the relevant rejection cases and essential variants. Use only cases applicable to this ticket; do not pad the list.
4. Include minimal prerequisites only when needed to perform the test, preferably in the first step.

Exclude deployment instructions, environment/build reporting requests, PR metadata, source paths, internal event names, implementation explanations, automated test summaries, and broad regression plans unless explicitly requested or essential to the ticket's acceptance criteria.

Do not describe QA as completed. Do not expose secrets or internal-only values unnecessarily.

### Example shape

```text
Clients can cancel unfinished orders using DELETE <endpoint>, with normal authentication and no request body.

1. Create an unfinished order and cancel it as its owner. Expect 204, no response body, and cancelled status.
2. Cancel it again. Expect 409.
3. Try an order owned by an unrelated organization. Expect 403 and no status change.
4. Try a non-existent order ID. Expect 404.
```

This is a format example, not a source of expected behavior for other tickets.

## Publish or revise

- Use only `atlassian_tools`, `atlassian_read`, and `atlassian_write` for Jira operations; discover exact operation schemas before using them.
- If the user requests a draft, show the text without writing to Jira.
- If the user requests adding the comment, call `addCommentToJiraIssue` through `atlassian_write`. No separate draft approval is needed when the request and behavior are clear; respect tool confirmation prompts.
- Prefer ADF: one paragraph followed by an `orderedList` of `listItem` paragraphs, so Jira renders the numbering correctly.
- When asked to shorten or correct an existing comment, update that specific comment rather than add a duplicate. Obtain its ID from current context or a narrow issue-comment read; ask if the target is ambiguous. Never overwrite an unrelated person's comment.
- The `editJiraIssue` operation supports `update.comment` with `[{"edit":{"id":"<comment-id>","body":<ADF>}}]`. Discover the current schema before calling it.
- Verify the write result. If an edit returns no body, read the issue's `comment` field and confirm the target comment's text. Never retry a write blindly or claim success on an error.
- Do not alter issue status, description, assignment, or any other fields.
- Finish with one sentence confirming the comment was added or updated, linking it when possible. Do not repeat the whole comment.
