local FixErrorAtCursor = function(gp, params)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_line, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  cursor_line = cursor_line - 1 -- Convert to 0-based index

  local diagnostics = vim.diagnostic.get(bufnr)

  local cursor_diagnostic = nil
  for _, diagnostic in ipairs(diagnostics) do
    if diagnostic.lnum == cursor_line and diagnostic.col <= cursor_col and cursor_col <= diagnostic.end_col then
      cursor_diagnostic = diagnostic
      break
    end
  end

  if not cursor_diagnostic then
    print("No diagnostic found at cursor position")
    return
  end

  local error_message = string.format(
    "Error at Line %d: %s [%s]. Source: %s\n",
    cursor_diagnostic.lnum + 1,
    cursor_diagnostic.message,
    cursor_diagnostic.code or "N/A",
    cursor_diagnostic.source or "N/A"
  )

  -- Select the entire range of the error
  vim.api.nvim_win_set_cursor(0, { cursor_diagnostic.lnum + 1, cursor_diagnostic.col })
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, { cursor_diagnostic.end_lnum + 1, cursor_diagnostic.end_col })

  local selected_text = vim.fn.getline(cursor_diagnostic.lnum + 1, cursor_diagnostic.end_lnum + 1)
  local selection = table.concat(selected_text, "\n")

  local template = "Having following from {{filename}}:\n\n"
    .. "```lua\n"
    .. selection
    .. "\n```\n\n"
    .. "Error found at the cursor:\n"
    .. error_message
    .. "Please respond by fixing the error above."
    .. "\n\nRespond exclusively with the snippet that should replace the selection above."

  local agent = gp.get_command_agent()
  gp.logger.info("Fixing error at cursor with agent: " .. agent.name)

  gp.Prompt(
    params,
    gp.Target.rewrite,
    agent,
    template,
    nil, -- command will run directly without any prompting for user input
    nil -- no predefined instructions
  )
end

return {
  "robitx/gp.nvim",
  config = function()
    require("gp").setup({
      hooks = {
        FixErrorAtCursor = FixErrorAtCursor,
      },
      providers = {
        openai = {},
        anthropic = {
          endpoint = "https://api.anthropic.com/v1/messages",
          secret = { "secret-tool", "lookup", "ai", "key" },
        },
      },
    })

    -- Setup shortcuts here (see Usage > Shortcuts in the Documentation/Readme)
    vim.keymap.set("v", "<leader>ar", ":<C-u>'<,'>GpRewrite<cr>", {})
    vim.keymap.set("v", "<leader>ac", ":<C-u>'<,'>GpChatToggle<cr>", {})
    vim.keymap.set("v", "<leader>af", ":<C-u>'<,'>GpFixErrorAtCursor<cr>", {})
  end,
}
