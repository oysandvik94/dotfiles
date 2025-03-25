local M = {}

---@enum (key) Mode
local theme = {
  light = "dayfox",
  dark = "tokyonight-moon",
}

---@param callback fun(mode: Mode)
local detect = function(callback)
  vim.system(
    {
      "gsettings",
      "get",
      "org.gnome.desktop.interface",
      "gtk-theme"
    },
    { text = true },
    ---@param obj vim.SystemCompleted
    vim.schedule_wrap(function(obj)
      callback(vim.trim(obj.stdout))
    end)
  )
end

M.update = function()
  detect(function(mode)
    local actual_mode = "dark";
    if string.find(mode, "dark") then
      actual_mode = "dark"
    else
      actual_mode = "light"
    end
    vim.api.nvim_cmd({
      cmd = "colorscheme",
      args = { theme[actual_mode] },
    }, {})

    -- require("nvim-highlight-colors").turnOn()
  end)
end

return M
