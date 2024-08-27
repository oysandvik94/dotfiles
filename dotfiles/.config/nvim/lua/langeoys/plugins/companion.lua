return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"nvim-telescope/telescope.nvim", -- Optional
		{
			"stevearc/dressing.nvim", -- Optional: Improves the default Neovim UI
			opts = {},
		},
	},
	config = function()
		require("codecompanion").setup({
			strategies = {
				chat = {
					adapter = "anthropic",
				},
				inline = {
					adapter = "anthropic",
				},
				agent = {
					adapter = "anthropic",
				},
			},
			adapters = {
				anthropic = function()
					return require("codecompanion.adapters").extend("anthropic", {
						env = {
							api_key = "cmd:secret-tool lookup ai key",
						},
					})
				end,
			},
		})

		vim.api.nvim_set_keymap("n", "<leader>ai", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("v", "<leader>ai", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "<leader>at", "<cmd>CodeCompanionToggle<cr>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("v", "<leader>at", "<cmd>CodeCompanionChat<cr>", { noremap = true, silent = true })

		-- Expand 'cc' into 'CodeCompanion' in the command line
		vim.cmd([[cab cc CodeCompanion]])
	end,
}
