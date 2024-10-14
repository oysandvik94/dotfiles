return {
	"jackMort/tide.nvim",
	config = function()
		require("tide").setup({
			-- optional configuration
		})
	end,
	requires = {
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons",
	},
}
