import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateHead } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { Type } from "typebox";

const SERVER = "/home/sandvoys/bin/banktech-mcp/target/release/atlassian-mcp";
const MAX_OUTPUT_BYTES = 25_000;
const WRITES = [
  "editJiraIssue", "createJiraIssue", "addCommentToJiraIssue", "addJiraWorklog", "transitionJiraIssue",
  "createConfluencePage", "updateConfluencePage", "createConfluenceFooterComment", "createConfluenceInlineComment",
  "uploadConfluenceAttachment", "downloadConfluenceAttachment", "addConfluencePageLabels", "removeConfluencePageLabel",
  "restoreConfluencePageVersion", "resolveConfluenceInlineComment", "reopenConfluenceInlineComment", "replyToConfluenceComment",
  "moveConfluencePage", "trashConfluencePage", "restoreConfluencePageFromTrash",
] as const;
const READS = [
  "setup", "getAccessibleAtlassianResources", "getJiraIssue", "searchJiraIssuesUsingJql",
  "getTransitionsForJiraIssue", "getJiraIssueRemoteIssueLinks", "getVisibleJiraProjects",
  "getJiraProjectIssueTypesMetadata", "lookupJiraAccountId", "getConfluenceSpaces", "getConfluencePage",
  "getPagesInConfluenceSpace", "getConfluencePageAncestors", "getConfluencePageDescendants",
  "getConfluencePageFooterComments", "getConfluencePageInlineComments", "listConfluenceAttachments",
  "convertContentToStorage", "getConfluencePageLabels", "listConfluencePageVersions",
  "getConfluencePageIncomingLinks", "searchConfluenceUsingCql",
] as const;

type McpTool = { name: string; description?: string; inputSchema: object };

function serverEnv(): Record<string, string> {
  const allowed = new Set(["PATH", "HOME", "USER", "LOGNAME", "SHELL", "DBUS_SESSION_BUS_ADDRESS", "XDG_RUNTIME_DIR", "DISPLAY", "WAYLAND_DISPLAY"]);
  return Object.fromEntries(Object.entries(process.env).filter(([key, value]) => value !== undefined && (allowed.has(key) || key.startsWith("ATLASSIAN_")))) as Record<string, string>;
}

function bounded(text: string): string {
  const result = truncateHead(text, { maxLines: 500, maxBytes: MAX_OUTPUT_BYTES });
  return result.truncated ? `${result.content}\n\n[Output truncated to 500 lines / 25KB.]` : result.content;
}

function resultText(result: any): string {
  const parts = (result.content ?? []).map((item: any) => item.type === "text" ? item.text : JSON.stringify(item));
  return bounded(parts.join("\n") || JSON.stringify(result));
}

export default function (pi: ExtensionAPI) {
  let client: Client | undefined;
  let tools: McpTool[] | undefined;

  async function connect(): Promise<Client> {
    if (client) return client;
    const next = new Client({ name: "pi-atlassian-mcp", version: "1" });
    await next.connect(new StdioClientTransport({ command: SERVER, args: ["stdio"], env: serverEnv(), stderr: "pipe" }));
    client = next;
    tools = (await next.listTools()).tools as McpTool[];
    return next;
  }

  async function call(name: string, args: Record<string, unknown>, signal?: AbortSignal): Promise<string> {
    const result = await (await connect()).callTool({ name, arguments: args }, undefined, { signal });
    const text = resultText(result);
    if (result.isError) throw new Error(text);
    return text;
  }

  pi.registerTool({
    name: "atlassian_tools",
    label: "Atlassian Tools",
    description: "List available Jira/Confluence MCP operations and their exact input schemas. Optionally filter by operation name.",
    promptSnippet: "Discover exact Jira and Confluence operation schemas",
    promptGuidelines: ["Use atlassian_tools to inspect an operation's schema before calling atlassian_read or atlassian_write when its arguments are not already known."],
    parameters: Type.Object({ name: Type.Optional(Type.String({ description: "Exact operation name or case-insensitive substring" })) }),
    async execute(_id, params, signal) {
      await connect();
      signal?.throwIfAborted();
      const query = params.name?.toLowerCase();
      const found = (tools ?? []).filter((tool) => !query || tool.name.toLowerCase().includes(query));
      return { content: [{ type: "text", text: bounded(JSON.stringify(found, null, 2)) }], details: { count: found.length } };
    },
  });

  pi.registerTool({
    name: "atlassian_read",
    label: "Atlassian Read",
    description: "Run one read-only Jira/Confluence MCP operation. Use atlassian_tools first for the exact argument schema. Output is limited to 500 lines / 25KB.",
    promptSnippet: "Read or search Jira and Confluence",
    promptGuidelines: ["Use atlassian_read for Jira/Confluence reads and searches. Never use it for a mutation."],
    parameters: Type.Object({
      tool: StringEnum(READS),
      arguments: Type.Optional(Type.Record(Type.String(), Type.Unknown(), { description: "Arguments matching the operation's MCP input schema" })),
    }),
    async execute(_id, params, signal, onUpdate) {
      onUpdate?.({ content: [{ type: "text", text: `Calling ${params.tool}…` }] });
      const text = await call(params.tool, params.arguments ?? {}, signal);
      return { content: [{ type: "text", text }], details: { tool: params.tool } };
    },
  });

  pi.registerTool({
    name: "atlassian_write",
    label: "Atlassian Write",
    description: "Run one Jira/Confluence or attachment mutation. Use atlassian_tools first for the exact argument schema. Writes are never retried automatically.",
    promptSnippet: "Modify Jira or Confluence when explicitly requested",
    promptGuidelines: [
      "Use atlassian_write only when the user explicitly requests the exact Jira/Confluence mutation.",
      "Do not claim an Atlassian write succeeded unless atlassian_write reports success.",
    ],
    parameters: Type.Object({
      tool: StringEnum(WRITES),
      arguments: Type.Record(Type.String(), Type.Unknown(), { description: "Arguments matching the operation's MCP input schema" }),
    }),
    async execute(_id, params, signal, onUpdate) {
      onUpdate?.({ content: [{ type: "text", text: `Calling ${params.tool}…` }] });
      const text = await call(params.tool, params.arguments, signal);
      return { content: [{ type: "text", text }], details: { tool: params.tool } };
    },
  });

  pi.on("session_shutdown", async () => {
    await client?.close().catch(() => undefined);
    client = undefined;
    tools = undefined;
  });
}
