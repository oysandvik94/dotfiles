import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.registerShortcut("alt+k", {
		description: "Open skill palette without changing the current prompt",
		handler: () => pi.sendUserMessage("/skill", { expandPromptTemplates: true }),
	});
}
