return {
	"yetone/avante.nvim",
	enabled = false,
	event = "VeryLazy",
	opts = {},
	build = "make",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		{
			"grapp-dev/nui-components.nvim",
			dependencies = {
				"MunifTanjim/nui.nvim",
			},
		},
		"nvim-lua/plenary.nvim",
		"MeanderingProgrammer/render-markdown.nvim",
	},
}
