Statusline = {}

local modules = require("langeoys.utils.statusline.modules")

local group = vim.api.nvim_create_augroup("Statusline", { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = group,
  desc = "Activate statusline on focus",
  callback = function()
    if vim.bo.filetype == "snacks_picker_input" then
      return
    end
    vim.opt_local.statusline = "%!v:lua.Statusline.active()"
  end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
  group = group,
  desc = "Deactivate statusline when unfocused",
  callback = function()
    vim.opt_local.statusline = "%!v:lua.Statusline.inactive()"
  end,
})

function Statusline.active()
  return table.concat {
    "[", modules.filepath(), modules.filename(), "]%m%r ",
    modules.git(),
    "%=",
    modules.macro() .. " ",
    modules.search() .. " ",
    "%y [%P %l:%c]"
  }
end

function Statusline.inactive()
  return " %t"
end
