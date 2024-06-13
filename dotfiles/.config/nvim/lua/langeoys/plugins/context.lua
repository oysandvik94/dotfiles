return {
	"nvim-treesitter/nvim-treesitter-context",
	enabled = false,
	config = function()
		require("nvim-treesitter.configs").setup({
			context = {
				enable = true,
				max_lines = 3,
				multiline_threshold = 3,
			},
		})
	end,
}
