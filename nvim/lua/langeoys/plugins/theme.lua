return {
	{
		"rose-pine/neovim",
		config = function()
			require("rose-pine").setup({
				variant = "main",
				-- disable_background = true,
				-- disable_float_background = true,
			})
		end,
	},
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
	{ "matsuuu/pinkmare" },
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
	{ "ellisonleao/gruvbox.nvim", priority = 1000, config = true, opts = ... },
	{ "miikanissi/modus-themes.nvim", priority = 1000 },
	{
		"HoNamDuong/hybrid.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
	},
}
