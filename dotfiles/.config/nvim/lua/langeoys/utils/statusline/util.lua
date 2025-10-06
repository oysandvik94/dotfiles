local M = {}

local config = {
  icons = {
    path_hidden = " " -- opened directory icon
  },
  highlights = {
    icon = "StatusLineIcon", -- a dim highlight group we define below
    text = "StatusLineText", -- a dim highlight group we define below
  }
}
M.config = config

-- set (or link) the dim highlight once
-- vim.api.nvim_set_hl(0, config.placeholder_hl, {}) -- create if missing
-- link to `Comment` to keep it dim; adjust as you like
vim.api.nvim_set_hl(0, config.highlights.icon, { link = "Identifier" })
vim.api.nvim_set_hl(0, config.highlights.text, { link = "Character" })

M.hl = function(group, text)
  return string.format("%%#%s#%s%%*", group, text)
  -- Result: `%#group#text%*`
  -- `%#group#` tells the highlight group that must be applied to `text`.
  -- `%*` restores the normal highlight group.
end

M.text = function(text)
  return M.hl(config.highlights.text, text)
end

M.icon = function(icon)
  return M.hl(config.highlights.icon, icon)
end

return M
