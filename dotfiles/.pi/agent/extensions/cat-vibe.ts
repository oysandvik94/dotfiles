import { readFile } from "node:fs/promises";
import { basename, join } from "node:path";
import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
	type ReadonlyFooterDataProvider,
	type Theme,
} from "@earendil-works/pi-coding-agent";
import {
	type Component,
	type EditorTheme,
	type TUI,
	truncateToWidth,
	visibleWidth,
} from "@earendil-works/pi-tui";

type EditorFactory = NonNullable<ReturnType<ExtensionContext["ui"]["getEditorComponent"]>>;

type GitState = {
	isRepo: boolean;
	branch?: string;
	changed: number;
	untracked: number;
};

type RunCost = {
	dir?: string;
	reported: number;
};

type LiveRunCost = RunCost & {
	key: string;
};

const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const SUBAGENT_RPC_REQUEST_EVENT = "subagents:rpc:v1:request";
const SUBAGENT_RPC_REPLY_PREFIX = "subagents:rpc:v1:reply:";

function fitRail(required: string, optional: string, right: string, width: number): string {
	if (width < 1) return "";

	const fittedRequired = truncateToWidth(required, width, "");
	if (visibleWidth(required) >= width) return fittedRequired;

	let remaining = width - visibleWidth(fittedRequired);
	const fittedRight = right && visibleWidth(right) + 1 <= remaining ? right : "";
	remaining -= visibleWidth(fittedRight) + (fittedRight ? 1 : 0);
	const fittedOptional = optional && visibleWidth(optional) <= remaining ? optional : "";
	const left = fittedRequired + fittedOptional;
	const gap = Math.max(fittedRight ? 1 : 0, width - visibleWidth(left) - visibleWidth(fittedRight));
	return `${left}${" ".repeat(gap)}${fittedRight}`;
}

function parseGitStatus(output: string): GitState {
	const lines = output.trimEnd().split("\n");
	const head = lines[0]?.startsWith("## ") ? lines.shift()!.slice(3) : "";
	let branch: string | undefined;

	if (head.startsWith("No commits yet on ")) branch = head.slice("No commits yet on ".length);
	else if (head.startsWith("HEAD ")) branch = "detached";
	else branch = head.split("...")[0]?.split(" ")[0] || undefined;

	let changed = 0;
	let untracked = 0;
	for (const line of lines) {
		if (line.startsWith("??")) untracked++;
		else if (line.trim()) changed++;
	}
	return { isRepo: true, branch, changed, untracked };
}

function formatContext(ctx: ExtensionContext, compact: boolean): string {
	const usage = ctx.getContextUsage();
	if (!usage || usage.percent === null) return compact ? "?%" : "ctx ?";
	const value = `${Math.round(usage.percent)}%/${Math.round(usage.contextWindow / 1000)}k`;
	return compact ? value : `ctx ${value}`;
}

function usageCost(value: unknown): number {
	if (!value || typeof value !== "object") return 0;
	const usage = value as { cost?: number | { total?: unknown }; costUsd?: unknown };
	const cost = typeof usage.costUsd === "number"
		? usage.costUsd
		: typeof usage.cost === "number"
			? usage.cost
			: usage.cost?.total;
	return typeof cost === "number" && Number.isFinite(cost) ? cost : 0;
}

function resultCost(value: unknown): number {
	if (!value || typeof value !== "object") return 0;
	const result = value as { totalCost?: unknown; usage?: unknown };
	return usageCost(result.totalCost) || usageCost(result.usage);
}

function detailsCost(details: Record<string, unknown>): number {
	const aggregate = usageCost(details.totalCost);
	if (aggregate > 0) return aggregate;
	const results = Array.isArray(details.results) ? details.results : [];
	return results.reduce((sum, result) => sum + resultCost(result), 0);
}

function entryTimestamp(entry: unknown): number | undefined {
	if (!entry || typeof entry !== "object") return undefined;
	const record = entry as { timestamp?: unknown; message?: { timestamp?: unknown } };
	const value = record.timestamp ?? record.message?.timestamp;
	if (typeof value !== "string") return undefined;
	const parsed = Date.parse(value);
	return Number.isFinite(parsed) ? parsed : undefined;
}

function forkStart(entries: readonly unknown[]): number | undefined {
	for (const entry of entries) {
		if (!entry || typeof entry !== "object") continue;
		const record = entry as { type?: unknown; parentSession?: unknown };
		if (record.type === "session" && typeof record.parentSession === "string") return entryTimestamp(entry);
	}
	return undefined;
}

function entryIdentity(entry: unknown): string | undefined {
	if (!entry || typeof entry !== "object") return undefined;
	const id = (entry as { id?: unknown }).id;
	return typeof id === "string" && id ? id : undefined;
}

function parentCost(entries: readonly unknown[]): number {
	// Fork history belongs to the parent; entry ids prevent a copied record from
	// becoming a second current-session charge after the child header.
	const copiedBefore = forkStart(entries);
	const seen = new Set<string>();
	let total = 0;
	for (const entry of entries) {
		const record = entry as { type?: unknown; message?: { role?: unknown; usage?: unknown }; usage?: unknown; totalCost?: unknown };
		const timestamp = entryTimestamp(entry);
		const identity = entryIdentity(entry);
		if (copiedBefore !== undefined && timestamp !== undefined && timestamp < copiedBefore) continue;
		if (identity && seen.has(identity)) continue;
		if (identity) seen.add(identity);
		if (record.type === "message" && record.message?.role === "assistant") total += usageCost(record.message.usage);
		else if (record.type === "compaction" || record.type === "branch_summary") total += usageCost(record.usage) || usageCost(record.totalCost);
	}
	return total;
}

function subagentDetails(entry: unknown): Record<string, unknown> | undefined {
	if (!entry || typeof entry !== "object") return undefined;
	const record = entry as { type?: unknown; message?: unknown; details?: unknown };
	if (record.type === "message" && record.message && typeof record.message === "object") {
		const message = record.message as { role?: unknown; toolName?: unknown; details?: unknown };
		if (message.role === "toolResult" && message.toolName === "subagent" && message.details && typeof message.details === "object") {
			return message.details as Record<string, unknown>;
		}
	}
	if (!record.details || typeof record.details !== "object") return undefined;
	const details = record.details as { result?: { details?: unknown } };
	return details.result?.details && typeof details.result.details === "object"
		? (details.result.details as Record<string, unknown>)
		: undefined;
}

function formatCost(cost: number): string {
	if (cost === 0) return "≈$0.00";
	const digits = cost < 0.01 ? 4 : cost < 1 ? 3 : 2;
	return `≈$${cost.toFixed(digits)}`;
}

function fleetActiveCount(value: unknown): number | undefined {
	if (!value || typeof value !== "object") return undefined;
	const reply = value as { success?: unknown; data?: { fleet?: { totalActive?: unknown } } };
	const count = reply.success === true ? reply.data?.fleet?.totalActive : undefined;
	return typeof count === "number" && Number.isSafeInteger(count) && count >= 0 ? count : undefined;
}

function extensionStatuses(footerData: ReadonlyFooterDataProvider | undefined): string {
	if (!footerData) return "";
	return [...footerData.getExtensionStatuses()]
		.filter(([key, value]) => key !== "cat-vibe" && visibleWidth(value) > 0)
		.sort(([a], [b]) => a.localeCompare(b))
		.map(([, value]) => value.replace(/\s+/g, " ").trim())
		.join(" · ");
}

function themeRgb(theme: Theme, color: "accent" | "borderMuted"): [number, number, number] | undefined {
	const match = theme.getFgAnsi(color).match(/38;2;(\d+);(\d+);(\d+)/);
	return match ? [Number(match[1]), Number(match[2]), Number(match[3])] : undefined;
}

function fadeDivider(theme: Theme, width: number): string {
	if (width < 1) return "";
	const solidWidth = Math.min(width, Math.max(8, Math.floor(width * 0.28)));
	const fadeWidth = Math.max(0, Math.floor((width - solidWidth) * 0.9));
	const steps = Math.min(12, fadeWidth);
	const startRgb = themeRgb(theme, "accent");
	const endRgb = themeRgb(theme, "borderMuted");
	let line = theme.fg("accent", "━".repeat(solidWidth));

	for (let step = 0; step < steps; step++) {
		const start = Math.floor((step * fadeWidth) / steps);
		const end = Math.floor(((step + 1) * fadeWidth) / steps);
		const progress = steps === 1 ? 1 : step / (steps - 1);
		const glyph = progress < 0.55 ? "─" : progress < 0.78 ? "╌" : progress < 0.94 ? "┄" : "·";
		const text = glyph.repeat(end - start);
		if (startRgb && endRgb) {
			const rgb = startRgb.map((value, index) => Math.round(value + (endRgb[index]! - value) * progress));
			line += `\x1b[38;2;${rgb.join(";")}m${text}\x1b[39m`;
		} else {
			const color = progress < 0.35 ? "accent" : progress < 0.7 ? "dim" : "borderMuted";
			line += theme.fg(color, text);
		}
	}

	return `${line}${" ".repeat(Math.max(0, width - solidWidth - fadeWidth))}`;
}

class CatAvatar implements Component {
	constructor(
		private readonly uiTheme: () => Theme,
		private readonly getFrame: () => number,
		private readonly isWorking: () => boolean,
	) {}

	render(width: number): string[] {
		const theme = this.uiTheme();
		const frame = this.getFrame();
		const working = this.isWorking();
		const eyes = frame % 7 === 0 ? "-ˎ -" : "˚ˎ 。";
		const tail = frame % 2 === 0 ? ",)ノ" : ",)～";
		const paw = working ? (frame % 2 === 0 ? "づ⌨" : "っ⌨") : "";
		const note = working ? "pawing through the task…" : "ready to pounce";
		const cat = (text: string) => theme.fg(working ? "accent" : "muted", text);
		const coloredNote = theme.fg(working ? "accent" : "success", note);

		return [
			fadeDivider(theme, width),
			"",
			`${cat("  ╱|、")}  ${coloredNote}`,
			cat(` (${eyes}7${paw}`),
			cat("  |、˜〵"),
			cat(`  じしˍ${tail}`),
		].map((line) => truncateToWidth(line, width, ""));
	}

	invalidate(): void {}
}

class CatEditor extends CustomEditor {
	constructor(
		tui: TUI,
		theme: EditorTheme,
		keybindings: KeybindingsManager,
		private readonly uiTheme: () => Theme,
	) {
		super(tui, theme, keybindings);
	}

	render(width: number): string[] {
		const lines = super.render(width);
		if (lines.length < 2 || width < 1) return lines;

		const theme = this.uiTheme();
		const border = (corner: string) =>
			`${theme.fg("accent", corner)}${theme.fg("borderMuted", "─".repeat(Math.max(0, width - 1)))}`;
		lines[0] = border("┌");
		lines[lines.length - 1] = border("└");
		return lines;
	}
}

class EmptyFooter implements Component {
	render(): string[] {
		return [];
	}

	invalidate(): void {}
}

export default function catVibe(pi: ExtensionAPI) {
	let enabled = true;
	let working = false;
	let frame = 0;
	let timer: ReturnType<typeof setInterval> | undefined;
	let activeTui: TUI | undefined;
	let currentCtx: ExtensionContext | undefined;
	let previousEditor: EditorFactory | undefined;
	let previousTheme: Theme | undefined;
	let footerData: ReadonlyFooterDataProvider | undefined;
	let git: GitState = { isRepo: false, changed: 0, untracked: 0 };
	let sessionCost = 0;
	let gitRefreshVersion = 0;
	let costRefreshVersion = 0;
	let costDirty = true;
	let activeSubagents = 0;
	let subagentRpcSequence = 0;
	let cancelSubagentRpc: (() => void) | undefined;
	const activeTools = new Map<string, string>();
	const liveSubagentRuns = new Map<string, LiveRunCost>();

	const requestRender = () => activeTui?.requestRender();

	const stopTimer = () => {
		if (timer) clearInterval(timer);
		timer = undefined;
	};

	const startTimer = () => {
		if (timer || !enabled) return;
		timer = setInterval(() => {
			frame++;
			if ((costDirty || frame % 5 === 0) && currentCtx) {
				costDirty = false;
				void refreshCost(currentCtx);
			}
			if (frame % 2 === 0) refreshSubagentCount();
			requestRender();
		}, 420);
	};

	const refreshSubagentCount = () => {
		if (!enabled || cancelSubagentRpc) return;
		const requestId = `cat-vibe-${Date.now()}-${++subagentRpcSequence}`;
		let cleanup = () => {};
		const unsubscribe = pi.events.on(`${SUBAGENT_RPC_REPLY_PREFIX}${requestId}`, (reply) => {
			const count = fleetActiveCount(reply);
			cleanup();
			if (count === undefined || count === activeSubagents) return;
			activeSubagents = count;
			requestRender();
		});
		const timeout = setTimeout(() => cleanup(), 1500);
		cleanup = () => {
			clearTimeout(timeout);
			unsubscribe();
			if (cancelSubagentRpc === cleanup) cancelSubagentRpc = undefined;
		};
		cancelSubagentRpc = cleanup;
		pi.events.emit(SUBAGENT_RPC_REQUEST_EVENT, {
			version: 1,
			requestId,
			method: "status",
			params: {},
			source: { extension: "cat-vibe" },
		});
	};

	const refreshGit = async (ctx: ExtensionContext) => {
		const version = ++gitRefreshVersion;
		const result = await pi
			.exec("git", ["status", "--porcelain=v1", "--branch", "--untracked-files=normal"], {
				cwd: ctx.cwd,
				timeout: 2000,
			})
			.catch(() => undefined);
		if (ctx !== currentCtx || version !== gitRefreshVersion) return;
		git = result?.code === 0 ? parseGitStatus(result.stdout) : { isRepo: false, changed: 0, untracked: 0 };
		requestRender();
	};

	const refreshCost = async (ctx: ExtensionContext) => {
		const version = ++costRefreshVersion;
		const runs = new Map<string, RunCost>();
		const mergeRun = (key: string, run: RunCost) => {
			const previous = runs.get(key) || { reported: 0 };
			runs.set(key, {
				dir: run.dir || previous.dir,
				reported: Math.max(previous.reported, run.reported),
			});
		};

		const entries = ctx.sessionManager.getEntries();
		const parent = parentCost(entries);
		for (const entry of entries) {
			const details = subagentDetails(entry);
			if (!details) continue;
			const key = String(details.runId || details.asyncId || details.asyncDir || entry.id);
			mergeRun(key, {
				dir: typeof details.asyncDir === "string" ? details.asyncDir : undefined,
				reported: detailsCost(details),
			});
		}
		for (const live of liveSubagentRuns.values()) mergeRun(live.key, live);

		const childCosts = await Promise.all(
			[...runs.values()].map(async (run) => {
				if (!run.dir) return run.reported;
				try {
					const status = JSON.parse(await readFile(join(run.dir, "status.json"), "utf8")) as { totalCost?: unknown };
					return usageCost(status.totalCost) || run.reported;
				} catch {
					return run.reported;
				}
			}),
		);
		if (ctx !== currentCtx || version !== costRefreshVersion) return;
		sessionCost = parent + childCosts.reduce((sum, cost) => sum + cost, 0);
		requestRender();
	};

	const rememberLiveSubagent = (toolCallId: string, value: unknown) => {
		if (!value || typeof value !== "object") return;
		const details = (value as { details?: unknown }).details;
		if (!details || typeof details !== "object") return;
		const record = details as Record<string, unknown>;
		liveSubagentRuns.set(toolCallId, {
			key: String(record.runId || record.asyncId || record.asyncDir || `live:${toolCallId}`),
			dir: typeof record.asyncDir === "string" ? record.asyncDir : undefined,
			reported: detailsCost(record),
		});
		costDirty = true;
	};

	const railLines = (ctx: ExtensionContext, width: number): string[] => {
		const theme = ctx.ui.theme;
		const separator = theme.fg("dim", " · ");
		const compact = width < 48;
		const fullModel = ctx.model?.name || ctx.model?.id || "no model";
		const model = compact ? (ctx.model?.id || fullModel).replace(/^gpt-/i, "") : fullModel;
		const thinking = pi.getThinkingLevel();
		const branch = git.branch || footerData?.getGitBranch() || undefined;
		const location = `${basename(ctx.cwd)}${branch ? ` / ${branch}` : ""}`;
		const tool = [...activeTools.values()].at(-1);
		const activity = tool || (working ? "thinking" : "ready");
		const activityMark = working ? SPINNER[frame % SPINNER.length]! : "○";
		const statuses = extensionStatuses(footerData);
		const dirty = git.isRepo
			? git.changed || git.untracked
				? `${git.changed} changed${git.untracked ? ` +${git.untracked} new` : ""}`
				: "clean"
			: "";

		const coloredModel = theme.fg("customMessageLabel", theme.bold(model));
		const coloredThinking = theme.getThinkingBorderColor(thinking);
		const topRequired = compact
			? `${theme.fg("accent", theme.bold("RASMUS"))} ${coloredModel}${separator}${coloredThinking(thinking)}`
			: `${theme.fg("accent", theme.bold("RASMUS"))} ${theme.fg("dim", "//")} ${coloredModel}${separator}${coloredThinking(`think:${thinking}`)}`;
		const topRight = theme.fg("accent", location);
		const activityColor = working ? "accent" : "success";
		const agents = compact ? `sub:${activeSubagents}` : `${activeSubagents} subagent${activeSubagents === 1 ? "" : "s"}`;
		const coloredAgents = theme.fg(activeSubagents > 0 ? "accent" : "muted", agents);
		const cost = theme.fg("mdLink", `${formatCost(sessionCost)} ${compact ? "this session" : "this Pi session"}`);
		const bottomRequired = `${theme.fg(activityColor, `${activityMark} ${activity}`)}${separator}${coloredAgents}${separator}${cost}`;
		const context = theme.fg("muted", formatContext(ctx, compact));
		const bottomOptional = `${separator}${context}${statuses ? `${separator}${statuses}` : ""}`;
		const bottomRight = dirty ? theme.fg(dirty === "clean" ? "success" : "mdLink", dirty) : "";
		const rail = (line: string, color: "accent" | "borderMuted") => `${theme.fg(color, "▌ ")}${line}`;
		const contentWidth = Math.max(0, width - 2);

		return [
			truncateToWidth(rail(fitRail(topRequired, "", topRight, contentWidth), "accent"), width, ""),
			truncateToWidth(rail(fitRail(bottomRequired, bottomOptional, bottomRight, contentWidth), "borderMuted"), width, ""),
		];
	};

	const disableUi = (ctx: ExtensionContext) => {
		stopTimer();
		ctx.ui.setHeader(undefined);
		ctx.ui.setWidget("cat-avatar", undefined);
		ctx.ui.setWidget("rasmus-rail", undefined);
		ctx.ui.setEditorComponent(previousEditor);
		ctx.ui.setFooter(undefined);
		ctx.ui.setWorkingVisible(true);
		ctx.ui.setWorkingMessage();
		ctx.ui.setWorkingIndicator();
		ctx.ui.setStatus("cat-vibe", undefined);
		if (previousTheme) ctx.ui.setTheme(previousTheme);
		previousTheme = undefined;
		activeTui = undefined;
		footerData = undefined;
	};

	const enableUi = (ctx: ExtensionContext) => {
		if (ctx.mode !== "tui") return;

		previousTheme ||= ctx.ui.theme;
		ctx.ui.setTheme("rasmus");
		ctx.ui.setHeader(() => new EmptyFooter());
		ctx.ui.setWidget("cat-avatar", () => new CatAvatar(() => ctx.ui.theme, () => frame, () => working));
		ctx.ui.setWidget(
			"rasmus-rail",
			() => ({ render: (width) => railLines(ctx, width), invalidate() {} }),
			{ placement: "aboveEditor" },
		);
		ctx.ui.setEditorComponent((tui, theme, keybindings) => {
			activeTui = tui;
			return new CatEditor(tui, theme, keybindings, () => ctx.ui.theme);
		});
		ctx.ui.setFooter((tui, _theme, data) => {
			footerData = data;
			const unsubscribe = data.onBranchChange(() => {
				void refreshGit(ctx);
				tui.requestRender();
			});
			const footer = new EmptyFooter() as EmptyFooter & { dispose(): void };
			footer.dispose = () => {
				unsubscribe();
				if (footerData === data) footerData = undefined;
			};
			return footer;
		});
		ctx.ui.setWorkingVisible(false);
		ctx.ui.setStatus("cat-vibe", undefined);
		startTimer();
		void refreshGit(ctx);
		void refreshCost(ctx);
		refreshSubagentCount();
	};

	const applyUi = (ctx: ExtensionContext) => {
		if (enabled) enableUi(ctx);
		else if (ctx.mode === "tui") disableUi(ctx);
	};

	pi.on("session_start", (_event, ctx) => {
		currentCtx = ctx;
		working = false;
		sessionCost = 0;
		costDirty = true;
		activeSubagents = 0;
		cancelSubagentRpc?.();
		activeTools.clear();
		liveSubagentRuns.clear();
		if (ctx.mode === "tui") previousEditor = ctx.ui.getEditorComponent();
		applyUi(ctx);
	});

	pi.on("agent_start", () => {
		working = true;
		requestRender();
	});

	pi.on("tool_execution_start", (event) => {
		activeTools.set(event.toolCallId, event.toolName);
		requestRender();
	});

	pi.on("tool_execution_update", (event) => {
		if (event.toolName !== "subagent") return;
		rememberLiveSubagent(event.toolCallId, event.partialResult);
		refreshSubagentCount();
	});

	pi.on("tool_execution_end", (event) => {
		activeTools.delete(event.toolCallId);
		if (event.toolName === "subagent") {
			rememberLiveSubagent(event.toolCallId, event.result);
			refreshSubagentCount();
		}
		requestRender();
	});

	pi.on("turn_end", () => {
		if (!currentCtx) return;
		void refreshGit(currentCtx);
		void refreshCost(currentCtx);
	});

	pi.on("agent_settled", () => {
		working = false;
		activeTools.clear();
		requestRender();
		if (currentCtx) {
			void refreshGit(currentCtx);
			void refreshCost(currentCtx);
		}
	});

	pi.on("model_select", requestRender);
	pi.on("thinking_level_select", requestRender);
	pi.on("message_end", () => {
		if (currentCtx) void refreshCost(currentCtx);
	});

	pi.on("session_shutdown", (_event, ctx) => {
		if (enabled && ctx.mode === "tui") disableUi(ctx);
		else stopTimer();
		gitRefreshVersion++;
		costRefreshVersion++;
		cancelSubagentRpc?.();
		currentCtx = undefined;
		activeTui = undefined;
		footerData = undefined;
		activeTools.clear();
		liveSubagentRuns.clear();
	});

	pi.registerCommand("cat", {
		description: "Toggle Rasmus's cat vibe and Catwalk Rail",
		handler: async (_args, ctx) => {
			enabled = !enabled;
		applyUi(ctx);
		ctx.ui.notify(enabled ? "Rasmus is awake. Mrrp!" : "Rasmus is napping.", "info");
		},
	});
}

if (process.env.PI_CAT_SELF_TEST === "1") {
	const parsed = parseGitStatus("## main...origin/main\n M tracked.ts\n?? new.ts\n");
	if (parsed.branch !== "main" || parsed.changed !== 1 || parsed.untracked !== 1) {
		throw new Error("cat-vibe git status self-test failed");
	}
	const narrowRail = fitRail("left", " optional", "right", 8);
	if (visibleWidth(narrowRail) > 8 || narrowRail.includes("right")) {
		throw new Error("cat-vibe width self-test failed");
	}
	if (formatCost(12.734) !== "≈$12.73" || detailsCost({ totalCost: { costUsd: 0.25 }, results: [{ usage: { cost: 0.125 } }] }) !== 0.25) {
		throw new Error("cat-vibe cost self-test failed");
	}
	if (forkStart([{ type: "session", parentSession: "parent", timestamp: "2026-08-01T10:00:00Z" }]) !== Date.parse("2026-08-01T10:00:00Z") || parentCost([
		{ type: "session", parentSession: "parent", timestamp: "2026-08-01T10:00:00Z" },
		{ type: "message", id: "copied", timestamp: "2026-08-01T09:00:00Z", message: { role: "assistant", usage: { cost: 1 } } },
		{ type: "message", id: "owned", timestamp: "2026-08-01T10:01:00Z", message: { role: "assistant", usage: { cost: 2 } } },
	]) !== 2) {
		throw new Error("cat-vibe fork self-test failed");
	}
	if (fleetActiveCount({ success: true, data: { fleet: { totalActive: 3 } } }) !== 3) {
		throw new Error("cat-vibe subagent count self-test failed");
	}
	const divider = fadeDivider({ fg: (_color: string, text: string) => text, getFgAnsi: () => "" } as unknown as Theme, 80);
	if (visibleWidth(divider) !== 80 || !divider.includes("╌") || !divider.endsWith(" ")) {
		throw new Error("cat-vibe divider self-test failed");
	}
}
