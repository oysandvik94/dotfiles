return {
	-- url = "https://gitlab.com/schrieveslaach/sonarlint.nvim",
	dir = "$HOME/dev/general/sonarlint.nvim",
	dependencies = {
		"mfussenegger/nvim-jdtls",
		"neovim/nvim-lspconfig",
	},
	config = function()
		require("sonarlint").setup({
			server = {
				-- cmd = {
				-- 	"java",
				-- 	"-jar",
				-- 	"/home/oysandvik/Downloads/sonarlint-vscode-3.20.2/extension/server/sonarlint-ls.jar",
				-- 	-- Ensure that sonarlint-language-server uses stdio channel
				-- 	"-stdio",
				-- 	"-analyzers",
				-- 	"/home/oysandvik/Downloads/sonarlint-vscode-3.20.2/extension/analyzers/sonarjava.jar",
				-- },

				cmd = {
					"sonarlint-language-server",
					-- Ensure that sonarlint-language-server uses stdio channel
					"-stdio",
					"-analyzers",
					-- paths to the analyzers you need, using those for python and java in this example
					vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarpython.jar"),
					vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarcfamily.jar"),
					vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarjava.jar"),
				},
			},
			filetypes = {
				-- Requires nvim-jdtls, otherwise an error message will be printed
				"java",
			},
		})
	end,
}
