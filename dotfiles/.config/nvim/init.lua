require("langeoys.global")
require("langeoys")

local colorscheme = require("langeoys.utils.state").get_state("colorscheme")
if colorscheme then
	vim.cmd("colorscheme " .. colorscheme.colorscheme)
end
