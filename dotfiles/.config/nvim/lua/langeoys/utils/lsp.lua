local M = {}

M.on_attach = function(event)
	vim.lsp.inlay_hint.enable(true)

	local opts = { noremap = true, silent = true }
	vim.keymap.set("n", "gd", function()
		require("fzf-lua").lsp_definitions({
			jump_to_single_result = true,
		})
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
	-- vim.keymap.set("n", "<leader>lr", function()
	-- 	vim.lsp.buf.rename()
	-- end, opts)

	vim.keymap.set("n", "grr", function()
		require("fzf-lua").lsp_references({
			jump_to_single_result = true,
			ignore_current_line = true,
			ignoreDecleration = true,
		})
	end, {})
	vim.keymap.set("n", "<leader>fs", function()
		require("fzf-lua").lsp_workspace_symbols({})
	end, {})
	vim.keymap.set("n", "<leader>fd", function()
		require("fzf-lua").lsp_document_symbols({})
	end, {})
	vim.keymap.set("n", "<leader>lit", function()
		vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
	end)

	vim.keymap.set("n", "<leader>ge", function()
		require("langeoys.utils.rust").go_to_error()
	end)

	vim.keymap.set("n", "<leader>lq", function()
		require("fzf-lua").lsp_code_actions({
			-- winopts = {
			-- 	relative = "cursor",
			-- 	width = 0.6,
			-- 	height = 0.3,
			-- 	row = 1,
			-- },
			filter = function(action)
				return action.kind == vim.lsp.protocol.CodeActionKind.QuickFix or action.isPreferred
			end,
			context = {
				diagnostics = vim.lsp.diagnostic.get_line_diagnostics(),
			},
		})
	end, { noremap = true, silent = true })

	vim.keymap.set({ "n", "v" }, "<leader>lc", function()
		require("fzf-lua").lsp_code_actions({
			-- winopts = {
			-- 	relative = "cursor",
			-- 	width = 0.6,
			-- 	height = 0.3,
			-- 	row = 1,
			-- },
		})
	end, { noremap = true, silent = true })
end

return M
