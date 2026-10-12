import { ThinkingSelectorComponent, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getSupportedThinkingLevels } from "@earendil-works/pi-ai";

export default function (pi: ExtensionAPI) {
	pi.registerCommand("think", {
		description: "Select thinking level",
		handler: async (_args, ctx) => {
			const levels = ctx.model ? getSupportedThinkingLevels(ctx.model) : ["off" as const];
			const selected = await ctx.ui.custom<(typeof levels)[number] | undefined>((tui, _theme, _keybindings, done) => {
				const selector = new ThinkingSelectorComponent(pi.getThinkingLevel(), levels, done, () => done(undefined));
				return {
					render: (width) => selector.render(width),
					invalidate: () => selector.invalidate(),
					handleInput: (data) => {
						selector.getSelectList().handleInput(data);
						tui.requestRender();
					},
				};
			});
			if (selected) pi.setThinkingLevel(selected);
		},
	});
}
