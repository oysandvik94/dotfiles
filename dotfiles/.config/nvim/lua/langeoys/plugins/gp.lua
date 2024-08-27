return {
	"robitx/gp.nvim",
	config = function()
		require("gp").setup({
			providers = {
				openai = {},
				anthropic = {
					endpoint = "https://api.anthropic.com/v1/messages",
					secret = { "secret-tool", "lookup", "ai", "key" },
				},
			},
		})

		-- Setup shortcuts here (see Usage > Shortcuts in the Documentation/Readme)
		vim.keymap.set("v", "<leader>air", ":<C-u>'<,'>GpRewrite<cr>", {})
		vim.keymap.set("v", "<leader>aic", ":<C-u>'<,'>GpChatToggle<cr>", {})
	end,
}
