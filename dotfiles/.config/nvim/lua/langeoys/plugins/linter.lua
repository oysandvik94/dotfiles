return {
	"mfussenegger/nvim-lint",
	config = function()
		require("lint").linters_by_ft = {
			-- Bruker eslint lsp isteden
			-- typescript = { "eslint_d" },
			-- javascript = { "eslint_d" },
		}

		local pattern = "([^:]+):(%d+):(%d+):(.+)"
		local groups = { "file", "lnum", "col", "message" }
		local severity_map = {
			["error"] = vim.diagnostic.severity.ERROR,
			["warning"] = vim.diagnostic.severity.WARN,
			["information"] = vim.diagnostic.severity.INFO,
			["hint"] = vim.diagnostic.severity.HINT,
		}

		local lint_group = vim.api.nvim_create_augroup("lint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
			callback = function()
				require("lint").try_lint()
			end,
			group = lint_group,
			pattern = "*",
		})
	end,
}
