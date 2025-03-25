return {
	{
		"rose-pine/neovim",
		config = function()
			require("rose-pine").setup({
				variant = "main",
				disable_background = false,
				-- disable_float_background = true,
			})
		end,
	},
	{ "catppuccin/nvim",              name = "catppuccin", priority = 1000 },
	{
		"vague2k/vague.nvim",
		config = function()
			require("vague").setup({
				-- optional configuration here
			})
		end,
	},
	{ "miikanissi/modus-themes.nvim", priority = 1000 },
	{ "rebelot/kanagawa.nvim" },
	{
		"yorik1984/newpaper.nvim",
		priority = 1000,
		config = true,
	},
	{ "EdenEast/nightfox.nvim" },
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
