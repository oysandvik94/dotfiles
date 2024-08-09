vim.b.disable_autoformat = true

local java_utils = require("langeoys.utils.java")

vim.keymap.set("n", "<leader>jg", function()
	java_utils.navigate_to_input()
end, { desc = "Reset and toggle ui" })
