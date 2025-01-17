return {
  "stevearc/profile.nvim",
  config = function()
    local should_profile = os.getenv("NVIM_PROFILE")
    if should_profile then
      require("profile").instrument_autocmds()
      if should_profile:lower():match("^start") then
        require("profile").start("*")
      else
        require("profile").instrument("*")
      end
    end

    local function toggle_profile()
      local prof = require("profile")
      if prof.is_recording() then
        prof.stop()
        prof.export("lol.json")
        vim.notify(string.format("Wrote %s", "lol.json"))
        -- vim.ui.input({ prompt = "Save profile to:", completion = "file", default = "profile.json" }, function(filename)
        --   if filename then
        --     prof.export(filename)
        --     vim.notify(string.format("Wrote %s", filename))
        --   end
        -- end)
      else
        prof.start("*")
      end
    end
    vim.api.nvim_create_user_command('ToggleProfile', toggle_profile, {})
    vim.keymap.set("", "<f1>", ":ToggleProfile<CR>")
  end
}
