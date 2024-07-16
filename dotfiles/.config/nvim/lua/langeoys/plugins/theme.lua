return {
	{
		"rose-pine/neovim",
		config = function()
			require("rose-pine").setup({
				variant = "main",
				disable_background = true,
				-- disable_float_background = true,
			})
		end,
	},
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
	{
		"vague2k/vague.nvim",
		config = function()
			require("vague").setup({
				-- optional configuration here
			})
		end,
	},
	{ "rebelot/kanagawa.nvim" },
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
	},
	{
		"Shatur/neovim-ayu",
		config = function()
			require("ayu").setup({
				mirage = true,
			})
		end,
	},
}
