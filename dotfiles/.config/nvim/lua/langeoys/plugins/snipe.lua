return {
	"leath-dub/snipe.nvim",
	keys = {
		{
			"<leader>s",
			function()
				require("snipe").open_buffer_menu({ max_path_width = 1 })
			end,
			desc = "Open Snipe buffer menu",
		},
	},
	opts = {},
}
