return {
	"mfussenegger/nvim-lint",
	config = function()
		require("lint").linters_by_ft = {
			-- Bruker eslint lsp isteden
			-- typescript = { "eslint_d" },
			-- javascript = { "eslint_d" },
			kotlin = { "detekt" },
		}

		local pattern = "([^:]+):(%d+):(%d+):(.+)"
		local groups = { "file", "lnum", "col", "message" }
		local severity_map = {
			["error"] = vim.diagnostic.severity.ERROR,
			["warning"] = vim.diagnostic.severity.WARN,
			["information"] = vim.diagnostic.severity.INFO,
			["hint"] = vim.diagnostic.severity.HINT,
		}
		require("lint").linters.detekt = {
			cmd = "detekt",
			stdin = false,
			append_fname = true,
			args = { "--input" },
			stream = nil,
			ignore_exitcode = true,
			env = nil,
			parser = require("lint.parser").from_pattern(pattern, groups, severity_map, {
				source = "detekt",
			}),
		}
		local lint = require("lint")
		lint.linters.detekt = require("lint.util").wrap(lint.linters.detekt, function(diagnostic)
			diagnostic.severity = vim.diagnostic.severity.HINT
			return diagnostic
		end)

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
