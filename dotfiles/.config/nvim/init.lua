require("langeoys.global")
require("langeoys")
local ui = require("langeoys.utils.ui")

ui.remove_terminal_padding()
local colorscheme = require("langeoys.utils.state").get_state("colorscheme") or "rose-pine"
if colorscheme then
	local _, err = pcall(function()
		vim.cmd("colorscheme " .. colorscheme)
	end)

	ui.use_terminal_background(false)

	if err then
		P("Failed to load colorscheme: " .. colorscheme)
		P("Error: " .. err)
	end
end
