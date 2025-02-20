return {
	"stevearc/conform.nvim",
	opts = {},
	config = function()
		require("conform").formatters.memes = {
			command = "google-java-format",
			args = { "-a", "-" },
		}

		require("conform").formatters.customxmlformat = {
			command = "xmlformat",
			args = { "--indent", "4", "--overwrite", "-" },
		}

		require("conform").setup({
			timeout_ms = 2000,
			format_on_save = function(bufnr)
				if vim.g.AUTOFORMAT or vim.b[bufnr].AUTOFORMAT then
					return { timeout_ms = 500, lsp_fallback = true }
				end
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				-- Conform will run multiple formatters sequentially
				python = { "isort", "black" },
				-- Use a sub-list to run only the first available formatter
				-- java            = { "memes" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "fixjson" },
				css = { "prettier" },
				xml = { "customxmlformat" },
				html = { "prettier" },
				markdown = { "prettier" },
				bash = { "shfmt" },
				sh = { "shfmt" },
				c = { "clang-format" },
			},
		})

		vim.keymap.set({ "n" }, "<leader>gq", "gggqG<C-o>", { desc = "Format file according to formatter" })
		vim.keymap.set({ "x", "v" }, "<leader>lf", ":'<,'>Format<CR>", { desc = "Format file according to formatter" })
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

		vim.api.nvim_create_user_command("FormatDisable", function(args)
			if args.bang then
				-- FormatDisable! will disable formatting just for this buffer
				vim.b.disable_autoformat = true
			else
				vim.g.disable_autoformat = true
			end
		end, {
			desc = "Disable autoformat-on-save",
			bang = true,
		})
		vim.api.nvim_create_user_command("FormatEnable", function()
			vim.b.disable_autoformat = false
			vim.g.disable_autoformat = false
		end, {
			desc = "Re-enable autoformat-on-save",
		})
	end,
}
