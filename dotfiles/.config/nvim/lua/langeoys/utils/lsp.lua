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
	vim.keymap.set("n", "]d", function()
		local severities = { 1, 2, 3, 4 }

		for _, value in ipairs(severities) do
			if #vim.diagnostic.get(0, { severity = value }) > 0 then
				vim.diagnostic.goto_next({ severity = value })
				break;
			end
		end
	end, opts)
	vim.keymap.set("n", "[d", function()
		local severities = { 1, 2, 3, 4 }

		for _, value in ipairs(severities) do
			if #vim.diagnostic.get(0, { severity = value }) > 0 then
				vim.diagnostic.goto_prev({ severity = value })
				break;
			end
		end
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
	vim.keymap.set("n", "<leader>lie", function() vim.lsp.inlay_hint.enable()end)
	vim.keymap.set("n", "<leader>lid", function() vim.lsp.inlay_hint.enable(0, false)end)
end

return M
