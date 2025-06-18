return {
  -- "copilotlsp-nvim/copilot-lsp",
  dir = "~/dev/general/copilot-lsp",
  init = function()
    vim.g.copilot_nes_debounce = 200
    vim.lsp.enable("copilot_ls")
    -- Check if copilot has a suggestion before using tab
    vim.keymap.set({ "n", "i" }, "<tab>", function()
      -- Try to jump to the start of the suggestion edit.
      -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
      if vim.b[vim.api.nvim_get_current_buf()].nes_state then
        require("copilot-lsp.nes").walk_cursor_start_edit()
        return true
      end
      -- Fallback to default tab behavior
      return "<tab>"
    end, { expr = true })

    vim.keymap.set("n", "<Esc>", function()
      local result = require("copilot-lsp.nes").clear()
      if not result then
        vim.cmd.nohlsearch()
      end
    end)
  end,
}
