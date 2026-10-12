// Run with: node --test dotfiles/.pi/agent/tests/prompt-stash.test.mjs
import assert from "node:assert/strict";
import { test } from "node:test";
import promptStash from "../extensions/prompt-stash.ts";

test("stash survives reload, swaps drafts, clears, and stays session-local", async () => {
	let entries = [];
	let text = "original draft";
	let shortcut;
	const pi = {
		registerShortcut: (_key, options) => { shortcut = options.handler; },
		appendEntry: (customType, data) => entries.push({ type: "custom", customType, data }),
	};
	const ctx = {
		sessionManager: { getBranch: () => entries },
		ui: { getEditorText: () => text, setEditorText: (value) => { text = value; } },
	};
	promptStash(pi);
	await shortcut(ctx);
	assert.equal(text, "");
	promptStash(pi); // New extension instance after reload or session resume.
	text = "second draft";
	await shortcut(ctx);
	assert.equal(text, "original draft");
	text = "";
	await shortcut(ctx);
	assert.equal(text, "second draft");
	text = "third draft";
	await shortcut(ctx);
	assert.equal(text, ""); // Cleared stash must not restore an older entry.
	entries = []; // Switch to a new session without reloading the extension.
	text = "new session draft";
	await shortcut(ctx);
	assert.equal(text, "");
	await shortcut(ctx);
	assert.equal(text, "new session draft");
});
