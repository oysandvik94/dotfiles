---@module 'snacks'
require("langeoys.global")
require("langeoys")
local ui = require("langeoys.utils.ui")

ui.remove_terminal_padding()
ui.use_terminal_background(true)
require("langeoys.utils.theme").update()
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "TabLine", { bg = "none" })
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalNCFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
    vim.api.nvim_set_hl(0, "FzfLuaBorder", { bg = "none" })
  end,
})
