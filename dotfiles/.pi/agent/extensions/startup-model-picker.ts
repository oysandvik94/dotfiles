import { getSupportedThinkingLevels } from "@earendil-works/pi-ai";
import {
	DynamicBorder,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
	Container,
	fuzzyFilter,
	Input,
	type SelectItem,
	SelectList,
	Text,
} from "@earendil-works/pi-tui";

async function fuzzySelect(
	ctx: ExtensionContext,
	title: string,
	items: SelectItem[],
): Promise<string | undefined> {
	return ctx.ui.custom<string | undefined>((tui, theme, keybindings, done) => {
		const container = new Container();
		const input = new Input();
		const results = new Container();
		let list: SelectList;

		const rebuild = () => {
			const query = input.getValue();
			const filtered = query
				? fuzzyFilter(items, query, (item) => `${item.label} ${item.description ?? ""}`)
				: items;
			list = new SelectList(filtered, Math.min(items.length, 10), {
				selectedPrefix: (text) => theme.fg("accent", text),
				selectedText: (text) => theme.fg("accent", text),
				description: (text) => theme.fg("muted", text),
				scrollInfo: (text) => theme.fg("dim", text),
				noMatch: (text) => theme.fg("warning", text),
			});
			list.onSelect = (item) => done(item.value);
			list.onCancel = () => done(undefined);
			results.clear();
			results.addChild(list);
		};

		container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));
		container.addChild(new Text(theme.fg("accent", theme.bold(title)), 1, 0));
		container.addChild(input);
		container.addChild(results);
		container.addChild(new Text(theme.fg("dim", "type to search • ↑↓ navigate • enter select • esc exit"), 1, 0));
		container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));
		rebuild();

		let focused = false;
		return {
			get focused() {
				return focused;
			},
			set focused(value: boolean) {
				focused = value;
				input.focused = value;
			},
			render: (width: number) => container.render(width),
			invalidate: () => container.invalidate(),
			handleInput(data: string) {
				if (
					keybindings.matches(data, "tui.select.up") ||
					keybindings.matches(data, "tui.select.down") ||
					keybindings.matches(data, "tui.select.confirm") ||
					keybindings.matches(data, "tui.select.cancel")
				) {
					list.handleInput(data);
				} else {
					const previous = input.getValue();
					input.handleInput(data);
					if (input.getValue() !== previous) rebuild();
				}
				tui.requestRender();
			},
		};
	});
}

export default function startupModelPicker(pi: ExtensionAPI) {
	pi.on("session_start", async (event, ctx) => {
		if (event.reason !== "startup" || ctx.mode !== "tui") return;

		const lastModel = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;
		const lastThinkingLevel = pi.getThinkingLevel();
		const models = ctx.scopedModels.length
			? ctx.scopedModels.map(({ model }) => model)
			: ctx.modelRegistry.getAvailable();
		const choices = new Map(
			models
				.map((model) => [`${model.provider}/${model.id}`, model] as const)
				.sort(
					([a], [b]) =>
						Number(b === lastModel) - Number(a === lastModel) || a.localeCompare(b),
				),
		);

		if (!choices.size) {
			ctx.ui.notify("No configured models are available", "error");
			ctx.shutdown();
			return;
		}

		const choice = await fuzzySelect(
			ctx,
			"Select model for this session",
			[...choices].map(([value, model]) => ({ value, label: value, description: model.name })),
		);
		const selected = choice ? choices.get(choice) : undefined;
		if (!selected) {
			ctx.shutdown();
			return;
		}

		if (!(await pi.setModel(selected))) {
			ctx.ui.notify(`No API key for ${choice}`, "error");
			ctx.shutdown();
			return;
		}

		const levels = [...getSupportedThinkingLevels(selected)].sort(
			(a, b) => Number(b === lastThinkingLevel) - Number(a === lastThinkingLevel),
		);
		const thinkingChoice = await fuzzySelect(
			ctx,
			"Select thinking level",
			levels.map((level) => ({ value: level, label: level })),
		);
		const thinkingLevel = levels.find((level) => level === thinkingChoice);
		if (!thinkingLevel) {
			ctx.shutdown();
			return;
		}
		pi.setThinkingLevel(thinkingLevel);
	});
}
