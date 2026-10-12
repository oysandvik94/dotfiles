import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function promptStash(pi: ExtensionAPI) {
	pi.registerShortcut("alt+s", {
		description: "Stash or restore the current prompt",
		handler: async (ctx) => {
			const entry = ctx.sessionManager.getBranch().findLast(
				(entry) => entry.type === "custom" && entry.customType === "prompt-stash",
			);
			let stashed = entry?.type === "custom" && typeof entry.data === "string"
				? entry.data
				: undefined;
			const current = ctx.ui.getEditorText();

			if (stashed === undefined) {
				stashed = current;
				ctx.ui.setEditorText("");
			} else {
				ctx.ui.setEditorText(stashed);
				stashed = current || undefined;
			}
			pi.appendEntry("prompt-stash", stashed ?? null);
		},
	});
}
