require("langeoys.global")
require("langeoys")

local colorscheme = require("langeoys.utils.state").get_state("colorscheme") or "rose-pine"
if colorscheme then
	local _, err = pcall(function() vim.cmd("colorscheme " .. colorscheme) end)

	if err then
		P("Failed to load colorscheme: " .. colorscheme)
		P("Error: " .. err)
	end
end
