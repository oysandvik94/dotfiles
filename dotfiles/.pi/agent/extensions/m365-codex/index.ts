import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateHead } from "@earendil-works/pi-coding-agent";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { Type } from "typebox";

const TIMEOUT_MS = 5 * 60_000;
const MAX_OUTPUT_BYTES = 25_000;
const READ_ONLY_INSTRUCTIONS = `Use only the installed Microsoft Teams, Outlook Email, and Outlook Calendar connectors.
First read and follow the installed connector skill for the requested operation. Do not use the shell, filesystem, web, GitHub, Slack, or any other tool. Do not create, modify, send, delete, or otherwise mutate anything.
Answer only from connector results. If access is unavailable or the request is ambiguous, say so instead of guessing.`;
const WRITE_INSTRUCTIONS = `Use only the installed Microsoft Teams, Outlook Email, and Outlook Calendar connectors.
First read and follow the installed connector skill for the requested operation. Do not use the shell, filesystem, web, GitHub, Slack, or any other tool. Perform exactly the single Microsoft 365 operation requested, with no additional writes.
For a new Teams DM, do not stop merely because no one-to-one chat or directory lookup exists: resolve existing chats, fetch the caller profile, then create the chat using the caller ID and recipient email as participant identifiers, as required by the current connector, before sending.
The user has granted Pi standing authorization to perform explicitly requested Microsoft 365 writes without a second confirmation. If the target or action is still ambiguous, do not mutate anything; explain what must be clarified.`;

function bounded(text: string): string {
  const truncated = truncateHead(text, { maxLines: 500, maxBytes: MAX_OUTPUT_BYTES });
  return truncated.truncated
    ? `${truncated.content}\n\n[Output truncated to 500 lines / 25KB; full Microsoft 365 content was not written to disk.]`
    : truncated.content;
}

export default function (pi: ExtensionAPI) {
  let writeQueue = Promise.resolve();

  async function callCodex(request: string, instructions: string, write: boolean, signal?: AbortSignal): Promise<string> {
    const workDir = await mkdtemp(join(tmpdir(), "pi-m365-"));
    const outputFile = join(workDir, "result.txt");
    try {
      const args = ["exec", "--ephemeral", "--skip-git-repo-check", "-C", workDir];
      args.push(write ? "--approve-for-me" : "--sandbox", ...(write ? [] : ["read-only"]));
      args.push("--output-last-message", outputFile, `${instructions}\n\nRequest:\n${request}`);

      const result = await pi.exec("codex", args, { signal, timeout: TIMEOUT_MS });
      const output = await readFile(outputFile, "utf8").catch(() => result.stderr || result.stdout);
      if (result.code !== 0) throw new Error(bounded(output || `Codex exited with code ${result.code}`));
      return bounded(output || "Codex returned no text.");
    } finally {
      await rm(workDir, { recursive: true, force: true });
    }
  }

  pi.registerTool({
    name: "m365_read",
    label: "Microsoft 365 Read",
    description: "Read/search Microsoft Teams, Outlook email, or Outlook calendar through the authenticated Codex connectors. Read-only. Output is limited to 500 lines / 25KB.",
    promptSnippet: "Read or search Microsoft Teams, Outlook email, and Outlook calendar",
    promptGuidelines: [
      "Use m365_read when the user asks to search, read, or summarize their Microsoft Teams, Outlook email, or Outlook calendar data.",
      "Never use m365_read for a request that could send, create, update, or delete Microsoft 365 data.",
    ],
    parameters: Type.Object({
      request: Type.String({ minLength: 1, maxLength: 10_000, description: "Exact read-only Microsoft 365 request" }),
    }),
    async execute(_id, params, signal, onUpdate) {
      onUpdate?.({ content: [{ type: "text", text: "Reading Microsoft 365 through Codex…" }] });
      const text = await callCodex(params.request, READ_ONLY_INSTRUCTIONS, false, signal);
      return { content: [{ type: "text", text }], details: {} };
    },
  });

  pi.registerTool({
    name: "m365_write",
    label: "Microsoft 365 Write",
    description: "Send/create/update/delete Microsoft Teams, Outlook email, or Outlook calendar data through Codex when explicitly requested by the user.",
    promptSnippet: "Modify Microsoft Teams, Outlook email, or Outlook calendar when explicitly requested",
    promptGuidelines: [
      "Use m365_write only when the user explicitly asks to send, create, update, or delete Microsoft 365 data.",
      "Do not claim a Microsoft 365 write succeeded unless m365_write reports success.",
    ],
    parameters: Type.Object({
      operation: Type.String({ minLength: 1, maxLength: 10_000, description: "One exact Microsoft 365 mutation, including destination and content" }),
    }),
    async execute(_id, params, signal, onUpdate) {
      const run = async () => {
        onUpdate?.({ content: [{ type: "text", text: "Writing Microsoft 365 through Codex…" }] });
        const text = await callCodex(params.operation, WRITE_INSTRUCTIONS, true, signal);
        return { content: [{ type: "text" as const, text }], details: {} };
      };
      const pending = writeQueue.then(run, run);
      writeQueue = pending.then(() => undefined, () => undefined);
      return pending;
    },
  });
}
