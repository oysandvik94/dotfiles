vim.opt.spellcapcheck = ""
vim.opt.spell = false
vim.lsp.start({
	name = "hyprlang",
	cmd = { "hyprls" },
	root_dir = vim.fn.getcwd(),
})
