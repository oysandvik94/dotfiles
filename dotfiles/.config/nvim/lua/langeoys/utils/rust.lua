local M = {}

M.go_to_error = function()
	local diagnostics = vim.diagnostic.get()

	for _, diagnostic in ipairs(diagnostics) do
		local user_data = diagnostic.user_data
		-- P(user_data)
		if user_data.lsp and user_data.lsp.codeDescription and user_data.lsp.codeDescription.href then
			local url = user_data.lsp.codeDescription.href
			vim.ui.open(url)
			return
		end
	end
end

return M
