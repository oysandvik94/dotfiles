local M = {}

M.use_terminal_background = function(should_use)
	if not should_use then
		return
	end

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalNCFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
	vim.api.nvim_set_hl(0, "FzfLuaBorder", { bg = "none" })
end

M.remove_terminal_padding = function()
	vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
		callback = function()
			local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
			if not normal.bg then
				return
			end
			io.write(string.format("\027]11;#%06x\027\\", normal.bg))
		end,
	})

	vim.api.nvim_create_autocmd("UILeave", {
		callback = function()
			io.write("\027]111\027\\")
		end,
	})
end

return M
