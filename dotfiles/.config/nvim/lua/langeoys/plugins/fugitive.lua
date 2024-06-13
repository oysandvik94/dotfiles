return {
	"tpope/vim-fugitive",
	config = function()
		vim.keymap.set("n", "<leader>gg", ":tab G<CR>", {})
	end,
}
