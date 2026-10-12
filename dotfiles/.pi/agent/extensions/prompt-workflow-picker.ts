import { randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";
import { basename, dirname, resolve } from "node:path";
import {
	CONFIG_DIR_NAME,
	DynamicBorder,
	getAgentDir,
	getSettingsListTheme,
	parseFrontmatter,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Container, type SettingItem, SettingsList, Text } from "@earendil-works/pi-tui";

type Workflow = { name: string; description: string; rank: number; path?: string };

function discoverWorkflows(pi: ExtensionAPI, cwd: string): Workflow[] {
	const userDir = resolve(getAgentDir(), "prompts");
	const projectDir = resolve(cwd, CONFIG_DIR_NAME, "prompts");
	const workflows = new Map<string, Workflow>([["oneshot", {
		name: "oneshot", description: "Run a one-off task with Sonnet (fresh context, UI-only result)", rank: 3,
	}]]);

	for (const command of pi.getCommands()) {
		if (command.source !== "prompt") continue;
		const filePath = resolve(command.sourceInfo.path);
		const rank = dirname(filePath) === projectDir ? 2 : dirname(filePath) === userDir ? 1 : -1;
		if (rank < 0) continue;
		const name = basename(filePath, ".md");
		const current = workflows.get(name);
		if (!current || rank >= current.rank) workflows.set(name, { name, description: command.description ?? "Prompt workflow", rank, path: filePath });
	}

	return [...workflows.values()].sort((a, b) => a.name.localeCompare(b.name));
}

export default function (pi: ExtensionAPI) {
	const runs = new Map<string, ExtensionContext>();

	function rpc(channel: string, params: Record<string, unknown>): Promise<void> {
		return new Promise((resolve, reject) => {
			const requestId = randomUUID();
			const timer = setTimeout(() => {
				unsubscribe();
				reject(new Error("Subagent service did not reply; check that @tintinweb/pi-subagents is enabled"));
			}, 30_000);
			const unsubscribe = pi.events.on(`${channel}:reply:${requestId}`, (raw) => {
				clearTimeout(timer);
				unsubscribe();
				const reply = raw as { success: boolean; data?: unknown; error?: string };
				if (reply.success) resolve();
				else reject(new Error(reply.error ?? "Subagent request failed"));
			});
			pi.events.emit(channel, { ...params, requestId });
		});
	}

	function finish(raw: unknown) {
		const event = raw as { id: string; status: string; result?: string; error?: string };
		const ctx = runs.get(event.id);
		if (!ctx) return;
		// Consume synchronously, before the plugin schedules a main-model turn.
		pi.events.emit("subagents:rpc:consume", { requestId: randomUUID(), agentId: event.id });
		runs.delete(event.id);
		ctx.ui.notify(`Workflow ${event.id}: ${event.status}. Full result in /agents.`, event.error ? "error" : "info");
		ctx.ui.setWidget("workflow-result", [
			`Workflow ${event.id}: ${event.status} — full result in /agents`,
			...(event.error ?? event.result ?? "No output").slice(0, 4000).split("\n").slice(0, 12),
		]);
	}
	pi.events.on("subagents:completed", finish);
	pi.events.on("subagents:failed", finish);
	pi.on("session_shutdown", () => runs.clear());

	async function run(name: string, args: string, ctx: ExtensionContext) {
		try {
			const workflow = discoverWorkflows(pi, ctx.cwd).find((item) => item.name === name);
			if (!workflow) throw new Error(`Unknown workflow: ${name}`);
			let type = "oneshot";
			let prompt = args.trim();
			if (workflow.path) {
				const { frontmatter, body } = parseFrontmatter(readFileSync(workflow.path, "utf8"));
				if (typeof frontmatter.subagent !== "string" || !frontmatter.subagent.trim()) {
					throw new Error(`Workflow ${name} needs a subagent in its frontmatter`);
				}
				type = frontmatter.subagent;
				prompt = body.replace(/\$@|\$ARGUMENTS\b/g, () => args.trim());
			}
			if (!prompt) throw new Error("Usage: /workflow-picker oneshot <task>");
			await rpc("subagents:rpc:spawn", {
				type, prompt,
				options: {
					description: name, inheritContext: false, isBackground: true, cwd: ctx.cwd,
					onSpawned: (id: string) => runs.set(id, ctx),
				},
			});
			ctx.ui.notify(`Started ${name}; results stay out of the main conversation.`, "info");
		} catch (error) {
			ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
		}
	}

	async function pick(ctx: ExtensionContext) {
		if (ctx.mode !== "tui") return;
		if (!ctx.isIdle()) {
			ctx.ui.notify("Wait for the current run to finish", "warning");
			return;
		}

		const workflows = discoverWorkflows(pi, ctx.cwd);
		const selected = await ctx.ui.custom<string | undefined>((tui, theme, _keybindings, done) => {
			const container = new Container();
			container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));
			container.addChild(new Text(theme.fg("accent", theme.bold("Run Prompt Workflow")), 1, 0));

			const items: SettingItem[] = workflows.map((workflow) => ({
				id: workflow.name,
				label: workflow.name,
				description: workflow.description,
				currentValue: "",
				values: [""],
			}));
			const list = new SettingsList(items, Math.min(items.length, 10), getSettingsListTheme(), (name) => done(name), () => done(undefined), { enableSearch: true });
			container.addChild(list);
			container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));

			return {
				render: (width) => container.render(width),
				invalidate: () => container.invalidate(),
				handleInput: (data) => {
					list.handleInput(data);
					tui.requestRender();
				},
			};
		}, { overlay: true, overlayOptions: { width: "60%", minWidth: 50, maxHeight: "70%", margin: 2 } });
		if (!selected) return;

		const args = await ctx.ui.input("Task / additional instructions:");
		if (args === undefined) return;
		await run(selected, args, ctx);
	}

	pi.registerShortcut("alt+p", { description: "Run a prompt workflow", handler: pick });
	pi.registerCommand("workflow-picker", {
		description: "Run a fresh subagent workflow: /workflow-picker oneshot <task>",
		handler: async (args, ctx) => {
			if (!args.trim()) return pick(ctx);
			const [, name, instructions] = args.trim().match(/^(\S+)(?:\s+([\s\S]*))?$/)!;
			await run(name, instructions ?? "", ctx);
		},
	});
}
