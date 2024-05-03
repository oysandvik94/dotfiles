local M = {}

M.go_to_error = function()
	local current_line, _ = unpack(vim.api.nvim_win_get_cursor(0))
	local diagnostics = vim.diagnostic.get(0, { lnum = (current_line - 1) })

	for _, diagnostic in ipairs(diagnostics) do
		local user_data = diagnostic.user_data
		if user_data.lsp and user_data.lsp.codeDescription and user_data.lsp.codeDescription.href then
			local url = user_data.lsp.codeDescription.href
			vim.ui.open(url)
			return
		end
	end
end

return M
