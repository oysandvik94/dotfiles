return {
	"jackMort/tide.nvim",
	config = function()
		require("tide").setup({
			keys = {
				leader = "<leader>h",
				horizontal = "v",
				vertical = "s",
			},
			hints = {
				dictionary = "qwfpbjluy",
			},
			animation_fps = 60,
			animation_duration = 150,
		})
	end,
	requires = {
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons",
	},
}
