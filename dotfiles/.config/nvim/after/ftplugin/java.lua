-- vim.b.disable_autoformat = true

local java_utils = require("langeoys.utils.java")
local spring_utils = require("langeoys.utils.spring")

vim.keymap.set("n", "<leader>jg", function()
	java_utils.navigate_to_input()
end, { desc = "Reset and toggle ui" })

vim.api.nvim_create_user_command('JavaGo', function(opts)
	java_utils.navigate_to_given_input(opts.args)
end, { desc = "Navigate to input in Java", nargs = 1 })

vim.keymap.set("n", "<leader>js", function()
	spring_utils.list_processes()
end, { desc = "Reset and toggle ui" })
