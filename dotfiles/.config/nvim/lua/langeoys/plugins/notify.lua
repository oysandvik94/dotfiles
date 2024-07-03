return {
	"rcarriga/nvim-notify",
	config = function()
		local notify = require("notify")
		notify.setup({
			background_colour = "#FFFFFF",
		})

		vim.notify = notify
	end,
}
