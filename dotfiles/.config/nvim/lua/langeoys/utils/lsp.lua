local M = {}

M.on_attach = function(client, bufnr)
	local opts = { noremap = true, silent = true }
	vim.keymap.set("n", "gd", function()
		vim.lsp.buf.definition()
		vim.api.nvim_feedkeys("zz", "n", false)
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

	vim.keymap.set("n", "gr", function()
		require("fzf-lua").lsp_references({
			-- winopts = {
			-- 	relative = "cursor",
			-- 	width = 0.6,
			-- 	height = 0.3,
			-- 	row = 1,
			-- },
		})
		-- previewer=false
	end, {})
	vim.keymap.set("n", "<leader>lie", function() vim.lsp.inlay_hint.enable() end)
	vim.keymap.set("n", "<leader>lid", function() vim.lsp.inlay_hint.enable(0, false) end)


	vim.keymap.set("n", "<leader>ge", function() require("langeoys.utils.rust").go_to_error() end)
end

return M
