// Run with: node --test dotfiles/.pi/agent/tests/prompt-workflow-picker.test.mjs
// Uses the managed Pi installation; never starts a real agent or creates a PR.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import { test } from "node:test";

const install = join(homedir(), ".pi/agent/install");
const version = readFileSync(join(install, "current-version"), "utf8").trim();
const modules = join(install, "releases", version, "node_modules");
const require = createRequire(join(modules, "test-loader.cjs"));
const { createJiti } = require("jiti");
const jiti = createJiti(import.meta.url, {
	alias: {
		"@earendil-works/pi-coding-agent": join(modules, "@earendil-works/pi-coding-agent/dist/index.js"),
		"@earendil-works/pi-tui": join(modules, "@earendil-works/pi-tui/dist/index.js"),
	},
});
const picker = await jiti.import(fileURLToPath(new URL("../extensions/prompt-workflow-picker.ts", import.meta.url)), { default: true });

test("direct workflows use fresh agents and consume only their own UI-only results", async () => {
	const handlers = new Map();
	const commands = new Map();
	const notices = [];
	const widgets = [];
	const spawns = [];
	const consumed = [];
	const events = {
		on(channel, handler) {
			const listeners = handlers.get(channel) ?? new Set();
			handlers.set(channel, listeners);
			listeners.add(handler);
			return () => listeners.delete(handler);
		},
		emit(channel, payload) {
			for (const handler of [...(handlers.get(channel) ?? [])]) handler(payload);
		},
	};
	const promptPath = fileURLToPath(new URL("../prompts/draft-pr.md", import.meta.url));
	picker({
		events,
		on() {},
		registerShortcut() {},
		registerCommand: (name, options) => commands.set(name, options.handler),
		getCommands: () => [{ source: "prompt", sourceInfo: { path: promptPath }, description: "Draft PR" }],
		// No sendUserMessage, sendMessage, setModel or model-call API in this mock.
	});
	const ctx = {
		cwd: fileURLToPath(new URL("../../../..", import.meta.url)),
		ui: {
			notify: (...args) => notices.push(args),
			setWidget: (...args) => widgets.push(args),
		},
	};
	events.on("subagents:rpc:spawn", ({ requestId, ...spawn }) => {
		spawns.push(spawn);
		spawn.options.onSpawned(`agent-${spawns.length}`);
		events.emit(`subagents:rpc:spawn:reply:${requestId}`, { success: true, data: { id: `agent-${spawns.length}` } });
	});
	events.on("subagents:rpc:consume", ({ agentId }) => consumed.push(agentId));
	const run = commands.get("workflow-picker");
	await run("oneshot create a draft PR\nwith a concise title", ctx);
	assert.equal(spawns[0].type, "oneshot");
	assert.equal(spawns[0].prompt, "create a draft PR\nwith a concise title");
	assert.equal(spawns[0].options.inheritContext, false);
	assert.equal(spawns[0].options.isBackground, true);
	assert.equal(spawns[0].options.cwd, ctx.cwd);
	assert.equal(spawns[0].options.isolation, undefined);
	events.emit("subagents:completed", { id: "unrelated", status: "completed", result: "Ignore" });
	assert.deepEqual(consumed, []);
	events.emit("subagents:completed", { id: "agent-1", status: "completed", result: "https://example.test/pr/1" });
	assert.deepEqual(consumed, ["agent-1"]); // Synchronous: prevents the plugin's nudge.
	assert.match(widgets[0][1].join("\n"), /https:\/\/example.test\/pr\/1/);

	await run("draft-pr keep the title literal: $@", ctx);
	assert.equal(spawns[1].type, "oneshot");
	assert.match(spawns[1].prompt, /Additional user instructions: keep the title literal: \$@/);
	events.emit("subagents:failed", { id: "agent-2", status: "error", error: "gh failed" });
	assert.deepEqual(consumed, ["agent-1", "agent-2"]);
	assert.match(widgets[1][1].join("\n"), /gh failed/);

	await run("oneshot", ctx);
	await run("missing task", ctx);
	assert.equal(spawns.length, 2);
	assert.match(notices.at(-2)[0], /Usage:/);
	assert.match(notices.at(-1)[0], /Unknown workflow/);

	const agent = readFileSync(new URL("../agents/oneshot.md", import.meta.url), "utf8");
	const explore = readFileSync(new URL("../agents/Explore.md", import.meta.url), "utf8");
	for (const field of ["model", "thinking"]) {
		assert.equal(agent.match(new RegExp(`^${field}: (.+)$`, "m"))[1], explore.match(new RegExp(`^${field}: (.+)$`, "m"))[1]);
	}
});
