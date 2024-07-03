local M = {}

M.on_attach = function(event)
	local opts = { noremap = true, silent = true }
	vim.keymap.set("n", "gd", function()
		require("fzf-lua").lsp_definitions({})
	end, opts)
	vim.keymap.set("n", "gD", function()
		vim.lsp.buf.declaration()
		vim.api.nvim_feedkeys("zz", "n", false)
	end, opts)
	vim.keymap.set("n", "gi", function()
		vim.lsp.buf.implementation()
		vim.api.nvim_feedkeys("zz", "n", false)
	end, opts)
	vim.keymap.set("n", "K", function()
		vim.lsp.buf.hover()
	end, opts)
	vim.keymap.set("n", "<leader>lws", function()
		vim.lsp.buf.workspace_symbol()
	end, opts)
	vim.keymap.set("n", "<leader>ld", function()
		vim.diagnostic.open_float()
	end, opts)
	vim.keymap.set({ "n", "v" }, "<leader>lc", function()
		require("fzf-lua").lsp_code_actions({
			winopts = {
				relative = "cursor",
				width = 0.6,
				height = 0.3,
				row = 1,
			},
			previewer = false,
		})
	end, opts)
	vim.keymap.set("n", "<leader>lr", function()
		vim.lsp.buf.rename()
	end, opts)

	vim.keymap.set("n", "grr", function()
		require("fzf-lua").lsp_references({})
	end, {})
	vim.keymap.set("n", "<leader>lit", function()
		vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
	end)

	vim.keymap.set("n", "<leader>ge", function()
		require("langeoys.utils.rust").go_to_error()
	end)
end

return M
