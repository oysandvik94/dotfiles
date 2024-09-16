vim.opt.spellcapcheck = ""
vim.lsp.set_log_level("debug")
local root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1])
local client = vim.lsp.start({
	name = "anton",
	cmd = { vim.fn.expand("~/dev/general/piperscript/target/debug/son_of_anton") },
	root_dir = root_dir,
})
vim.lsp.buf_attach_client(0, client)
