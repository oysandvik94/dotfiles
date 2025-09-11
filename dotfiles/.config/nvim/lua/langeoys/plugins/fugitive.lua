return { {
	"tpope/vim-fugitive",
	config = function()
		vim.keymap.set("n", "<leader>gg", ":tab G<CR>", {})
	end,
}, {
	"tpope/vim-rhubarb",
} }
