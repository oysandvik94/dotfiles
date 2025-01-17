return {
	"nvim-treesitter/nvim-treesitter-context",
	config = function()
		require("nvim-treesitter.configs").setup({
			context = {
				enable = true,
				max_lines = 3,
				multiline_threshold = 3,
			},
		})
		vim.api.nvim_set_keymap('n', '<leader>uc', ':TSContextToggle<CR>', { noremap = true, silent = true })
	end,
}
