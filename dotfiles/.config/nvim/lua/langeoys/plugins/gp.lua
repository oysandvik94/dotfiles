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
	end,
}
