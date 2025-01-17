-- fold
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldcolumn = "0"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 0
vim.opt.foldnestmax = 4
vim.opt.foldtext = require("langeoys.utils.foldtext")
vim.opt.fillchars =
    {
      eob = " ",
      fold = " ",
      foldopen = "",
      foldclose = "",
      foldsep = " ", -- or "│" to use bar for show fold area
    },
    -- Indenting
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "*",
      callback = function()
        vim.opt_local.formatoptions:remove({ "o" })
      end,
    })
vim.opt.colorcolumn = "99"
