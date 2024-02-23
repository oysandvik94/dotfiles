require("langeoys.global")
require("langeoys")

local colorscheme = require("langeoys.utils.state").get_state("colorscheme") or "rose-pine"
if colorscheme.colorscheme then
	vim.cmd("colorscheme " .. colorscheme.colorscheme)
end
