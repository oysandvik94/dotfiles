vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    require("langeoys.jdtls_setup").setup()
  end,
  pattern = 'java'
})
