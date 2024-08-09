return {
	{
		"zbirenbaum/copilot.lua",
		enabled = true,
		dependencies = {
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
		opts = {},
		config = function()
			require("copilot").setup({
				suggestion = {
					-- auto_trigger = true,
					keymap = {
						accept = "<right>",
					},
				},
			})
		end,
	},
}
