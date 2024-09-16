require("langeoys.remap")
require("langeoys.set")
require("langeoys.autocommands")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local plugins = require("lazy").setup({ { import = "langeoys.plugins" }, { import = "langeoys.plugins.lsp" } })

vim.filetype.add({
	extension = {
		las = "piperscript",
	},
})

return plugins
