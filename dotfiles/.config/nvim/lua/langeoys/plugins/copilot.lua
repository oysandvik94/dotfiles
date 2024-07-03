return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "canary",
		enabled = false,
		dependencies = {
			{ "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
		opts = {},
		config = function()
			require("copilot").setup({
				suggestion = {
					auto_trigger = true,
					keymap = {
						accept = "<right>",
					},
				},
			})
			require("CopilotChat").setup({})
		end,
	},
}
