require("langeoys.global")
require("langeoys")

local colorscheme = require("langeoys.utils.state").get_state("colorscheme") or "rose-pine"
if colorscheme then
	local _, err = pcall(function() vim.cmd("colorscheme " .. colorscheme) end)
	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalNCFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
	vim.api.nvim_set_hl(0, "FzfLuaBorder", { bg = "none" })

	if err then
		P("Failed to load colorscheme: " .. colorscheme)
		P("Error: " .. err)
	end
end
