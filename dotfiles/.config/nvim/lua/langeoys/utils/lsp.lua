local M = {}

M.on_attach = function(client, bufnr)
  if client.name == "angularls" then
    client.server_capabilities.referencesProvider = vim.bo.filetype == 'html'
    client.server_capabilities.renameProvider = false
  end

  vim.lsp.inlay_hint.enable(true)

  local opts = { noremap = true, silent = true }
  vim.keymap.set("n", "gd", function()
    Snacks.picker.lsp_definitions({
      finder = "lsp_definitions",
      format = "file",
      include_current = false,
      auto_confirm = true,
    })
  end, opts)
  vim.keymap.set("n", "gD", function()
    vim.lsp.buf.declaration()
    vim.api.nvim_feedkeys("zz", "n", false)
  end, opts)
  vim.keymap.set("n", "gi", function()
    Snacks.picker.lsp_implementations({})
  end, opts)
  vim.keymap.set("n", "K", function()
    vim.lsp.buf.hover()
  end, opts)
  vim.keymap.set("n", "<leader>lws", function()
    vim.lsp.buf.workspace_symbol()
  end, opts)
  vim.keymap.set("n", "<leader>ld", function()
    vim.diagnostic.open_float()
  end, opts)
  -- vim.keymap.set("n", "<leader>lr", function()
  -- 	vim.lsp.buf.rename()
  -- end, opts)

  vim.keymap.set("n", "grr", function()
    Snacks.picker.lsp_references({
      finder = "lsp_references",
      format = "file",
      include_current = false,
      auto_confirm = true,
    })
  end, {})
  vim.keymap.set("n", "<leader>fd", function()
    Snacks.picker.lsp_symbols()
  end, {})
  vim.keymap.set("n", "<leader>lit", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end)

  vim.keymap.set("n", "<leader>ge", function()
    require("langeoys.utils.rust").go_to_error()
  end)

  vim.keymap.set({ "n", "v" }, "<leader>lc", vim.lsp.buf.code_action, { noremap = true, silent = true })
end

return M
