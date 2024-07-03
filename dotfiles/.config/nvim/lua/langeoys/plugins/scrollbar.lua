return {
	"petertriho/nvim-scrollbar",
	config = function()
		require("scrollbar").setup({
			handle = {
				-- color = "#524f67",
				color = "#6e6a86",
			},
			marks = {
				Cursor = {
					text = " ",
					color = "#f2966b",
				},
			},
		})
		require("scrollbar.handlers.gitsigns").setup()
	end,
}
