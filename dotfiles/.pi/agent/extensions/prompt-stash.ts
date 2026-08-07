import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function promptStash(pi: ExtensionAPI) {
	let stashed: string | undefined;

	pi.registerShortcut("alt+s", {
		description: "Stash or restore the current prompt",
		handler: async (ctx) => {
			const current = ctx.ui.getEditorText();

			if (stashed === undefined) {
				stashed = current;
				ctx.ui.setEditorText("");
			} else {
				ctx.ui.setEditorText(stashed);
				stashed = current || undefined;
			}
		},
	});
}
