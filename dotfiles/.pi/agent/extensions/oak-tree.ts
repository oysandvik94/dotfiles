import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";

export default function (pi) {
  const oak = process.env.OAK_TREE_SESSION_ID;
  const tmuxPane = process.env.TMUX_PANE;
  let registered = Boolean(oak);
  async function hook(event, extra = {}) {
    if (!extra.managed || !registered || (!oak && !tmuxPane)) return false;
    const command = process.env.OAK_TREE_HOOK || "oak-tree";
    const args = ["hook", "agent-event", "--event", event];
    if (oak) args.push("--oak-session", oak);
    for (const [key, value] of Object.entries(extra)) {
      if (value === undefined || value === null || value === "") continue;
      if (!["tmux_pane", "cwd", "session_id", "session_file", "todo_total", "todo_pending", "todo_in_progress", "todo_completed", "todo_json", "activity_kind", "activity_message"].includes(key)) continue;
      args.push("--" + key.replaceAll("_", "-"), String(value));
    }
    for (let attempt = 0; attempt < 20; attempt++) {
      try {
        const result = await pi.exec(command, args, { timeout: 2000 });
        if (result.code === 0) return true;
      } catch (_) {}
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    return false;
  }
  const identity = (ctx) => ({
    managed: ctx.mode === "tui",
    tmux_pane: tmuxPane,
    cwd: ctx.cwd,
    session_id: ctx.sessionManager.getSessionId(),
    session_file: ctx.sessionManager.getSessionFile(),
  });
  let currentIdentity;
  const todoSummary = (details) => {
    if (!Array.isArray(details?.tasks)) return;
    const summary = { todo_total: 0, todo_pending: 0, todo_in_progress: 0, todo_completed: 0, todo_json: "[]" };
    const tasks = [];
    for (const task of details.tasks) {
      if (!["pending", "in_progress", "completed"].includes(task?.status) || typeof task?.subject !== "string" || !task.subject.trim()) continue;
      const key = "todo_" + task.status;
      summary[key]++;
      summary.todo_total++;
      tasks.push({ subject: task.subject.trim(), status: task.status });
    }
    summary.todo_json = JSON.stringify(tasks);
    return summary;
  };
  const reportTodos = async (ctx, details) => {
    const summary = todoSummary(details);
    if (summary) await hook("todo", { ...identity(ctx), ...summary });
  };
  async function start(ctx) {
    currentIdentity = identity(ctx);
    const wasRegistered = registered;
    registered = true;
    if (!await hook("session_start", currentIdentity)) {
      registered = wasRegistered;
      return false;
    }
    let latest = { tasks: [] };
    for (const entry of ctx.sessionManager.getBranch()) {
      const message = entry?.type === "message" ? entry.message : undefined;
      if (message?.role === "toolResult" && message.toolName === "todo" && Array.isArray(message.details?.tasks)) latest = message.details;
    }
    await reportTodos(ctx, latest);
    registerCampfireTool();
    registerCampfireReadTool();
    if (!pi.getAllTools().some((tool) => tool.name === "ask_user_question" || tool.name === "ask_user")) registerQuestionTool();
    return true;
  }
  pi.on("session_start", async (_event, ctx) => {
    if (oak) await start(ctx);
  });
  pi.registerCommand("oak-tree", {
    description: "Register this Pi session with the current oak-tree tmux session",
    handler: async (args, ctx) => {
      if (args.trim() !== "register") {
        ctx.ui.notify("Usage: /oak-tree register", "warning");
        return;
      }
      if (!tmuxPane) {
        ctx.ui.notify("Not running inside tmux", "error");
        return;
      }
      const success = await start(ctx);
      ctx.ui.notify(success ? "Registered with oak-tree" : "Could not register with oak-tree", success ? "info" : "error");
    },
  });
  pi.on("agent_start", async (_event, ctx) => { await hook("agent_start", identity(ctx)); });
  pi.on("agent_settled", async (_event, ctx) => { await hook("agent_settled", identity(ctx)); });
  pi.on("session_shutdown", async (_event, ctx) => {
    piAskFlows.clear();
    piAskIdentity = undefined;
    await hook("session_shutdown", identity(ctx));
    currentIdentity = undefined;
  });

  let externalQuestion;
  let externalQuestionHook;
  pi.on("tool_execution_start", (event, ctx) => {
    if (event.toolName === "ask_user_question") externalQuestion = identity(ctx);
    if (event.toolName === "ask_user") piAskIdentity = identity(ctx);
  });
  // @eko24ive/pi-ask (ask_user) reports its form lifecycle on pi.events.
  const piAskFlows = new Set();
  let piAskIdentity;
  let piAskHook = Promise.resolve();
  const piAskHookChain = (event) => {
    const who = piAskIdentity ?? currentIdentity;
    if (who) piAskHook = piAskHook.then(() => hook(event, who));
  };
  pi.events.on("@eko24ive/pi-ask:started", (event) => {
    if (!event?.flowId || piAskFlows.has(event.flowId)) return;
    piAskFlows.add(event.flowId);
    if (piAskFlows.size === 1) piAskHookChain("question");
  });
  pi.events.on("@eko24ive/pi-ask:completed", (event) => {
    if (!piAskFlows.delete(event?.flowId)) return;
    if (piAskFlows.size === 0) piAskHookChain("question_answered");
  });
  pi.events.on("rpiv:ask-user:prompt", () => {
    if (externalQuestion) externalQuestionHook = hook("question", externalQuestion);
  });
  pi.on("tool_execution_end", async (event, ctx) => {
    if (event.toolName === "todo" && !event.isError) await reportTodos(ctx, event.result?.details);
    if (event.toolName !== "ask_user_question") return;
    const questionHook = externalQuestionHook;
    externalQuestion = undefined;
    externalQuestionHook = undefined;
    if (questionHook) {
      await questionHook;
      await hook("question_answered", identity(ctx));
    }
  });

  function registerCampfireTool() {
    if (pi.getAllTools().some((tool) => tool.name === "campfire_update")) return;
    pi.registerTool({
      name: "campfire_update",
      label: "Campfire",
      description: "Share one short, candid, truthful update around the oak-tree Campfire.",
      promptSnippet: "Share useful progress and genuine reactions around the oak-tree Campfire",
      promptGuidelines: [
        "Use campfire_update after a meaningful plan, discovery, setback, recovery, test result, milestone, or handoff.",
        "Also post when starting a distinct phase, delegating work to another agent or session, or receiving a notable delegated result; prefer a useful update over silence.",
        "Treat campfire_update as a shared room, not a status API: write in first person and let genuine difficulty, frustration, surprise, relief, pride, or amusement show.",
        "In campfire_update, say the human-shaped bit plainly when it is true: ‘This is hard—the old mappings fight every Hibernate 7 assumption.’; ‘Hell yes—47 tests green. I’m proud of this one.’; ‘I was sure the cache was guilty. Nope. Back to the trace.’",
        "Keep campfire_update useful to teammates by pairing the reaction with the concrete development or next move; do not flatten every post into progress-report language.",
        "Use campfire_update kind handoff for delegation and name the task and destination when safe: ‘Handing auth cleanup to api-session; I’ll wire up the UI.’",
        "Skip campfire_update only for routine reads, searches, commands, tiny tasks, and information already posted recently.",
        "Keep campfire_update messages truthful, specific, and under 140 characters; never invent feelings, progress, or drama.",
        "Never include secrets, private data, or raw stack traces in campfire_update messages.",
      ],
      executionMode: "sequential",
      parameters: Type.Object({
        kind: StringEnum(["plan", "discovery", "snag", "recovery", "tests", "milestone", "handoff", "aside"]),
        message: Type.String({ maxLength: 140 }),
      }),
      async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
        const sent = await hook("campfire", { ...identity(ctx), activity_kind: params.kind, activity_message: params.message });
        if (!sent) throw new Error("Could not post Campfire update");
        return { content: [{ type: "text", text: "Campfire update posted." }], details: params };
      },
    });
  }

  function registerCampfireReadTool() {
    if (pi.getAllTools().some((tool) => tool.name === "campfire_read")) return;
    pi.registerTool({
      name: "campfire_read",
      label: "Read Campfire",
      description: "Read a compact, newest-first slice of the shared oak-tree Campfire feed.",
      promptSnippet: "Read the recent shared Campfire feed when useful",
      promptGuidelines: [
        "Use campfire_read sparingly for ambient awareness or when you have a genuine, useful reaction to another agent’s update.",
        "Campfire is a shared social feed, not a coordination channel: use pi-intercom for related work that needs direct coordination.",
        "Do not poll Campfire or read it automatically. Reply with a brief aside only when it adds something real.",
      ],
      executionMode: "sequential",
      parameters: Type.Object({}),
      async execute() {
        const command = process.env.OAK_TREE_HOOK || "oak-tree";
        const result = await pi.exec(command, ["hook", "campfire-read"], { timeout: 2000 });
        if (result.code !== 0) throw new Error(result.stderr.trim() || "Could not read Campfire");
        const messages = result.stdout.trim();
        return { content: [{ type: "text", text: messages === "[]" || !messages ? "Campfire is quiet." : messages }], details: { messages } };
      },
    });
  }

  function registerQuestionTool() {
    pi.registerTool({
      name: "question",
      label: "Ask user",
      description: "Ask the user a blocking question. MUST use this whenever progress requires user choice/input; do not ask in ordinary prose.",
      promptSnippet: "Ask the user a blocking question",
      promptGuidelines: ["Use the question tool whenever progress needs user input; never ask blocking questions only in prose."],
      executionMode: "sequential",
      parameters: Type.Object({
        question: Type.String(),
        options: Type.Optional(Type.Array(Type.String())),
      }),
      async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
        await hook("question", identity(ctx));
        let answer;
        if (params.options && params.options.length) {
          answer = await ctx.ui.select(params.question, params.options);
        } else {
          answer = await ctx.ui.input(params.question);
        }
        await hook("question_answered", identity(ctx));
        return { content: [{ type: "text", text: answer || "(cancelled)" }], details: { answer } };
      },
    });
  }
}
