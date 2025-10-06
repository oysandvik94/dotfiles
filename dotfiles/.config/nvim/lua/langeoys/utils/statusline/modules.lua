local M = {}

local state = require("langeoys.utils.state")

local util = require("langeoys.utils.statusline.util")
local text = util.text
local icon = util.icon
local config = util.config

M.git = function()
  local git_info = vim.b.gitsigns_status_dict
  if not git_info or git_info.head == "" then
    return ""
  end

  local head    = git_info.head
  local added   = git_info.added and (" +" .. git_info.added) or ""
  local changed = git_info.changed and (" ~" .. git_info.changed) or ""
  local removed = git_info.removed and (" -" .. git_info.removed) or ""
  if git_info.added == 0 then added = "" end
  if git_info.changed == 0 then changed = "" end
  if git_info.removed == 0 then removed = "" end

  return table.concat({
    icon("[  "), -- branch icon
    text(head),
    added, changed, removed,
    "]",
  })
end

M.filepath = function()
  -- Modify the given file path with the given modifiers
  local fpath = vim.fn.fnamemodify(vim.fn.expand "%", ":~:.:h")

  if fpath == "" or fpath == "." then
    return ""
  end

  local marks = require("langeoys.utils.marks")
  local str = vim.fn.expand("%:t")
  if marks.is_marked(str) then
    fpath = icon("󰐷 ") .. text(fpath)
  end

  if state.get_state(state.STATUSLINE_FILEPATH) then
    return string.format("%%<%s/", fpath)
  end

  return icon("󰐷 ") .. icon(config.icons.path_hidden .. "/")
end

M.filename = function()
  local fname = vim.fn.expand("%:t")
  if fname == "" then
    return ""
  end
  return text(fname)
end

return M
