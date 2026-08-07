---@diagnostic disable: missing-fields
local parsers = {
  "regex",
  "markdown_inline",
  "vimdoc",
  "java",
  "javascript",
  "typescript",
  "c_sharp",
  "c",
  "lua",
  "vim",
  "sql",
  "markdown",
  "query",
  "html",
  "kotlin",
  "gitcommit",
}

return {
  -- Highlight, edit, and navigate code
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = function()
    local treesitter = require("nvim-treesitter")

    treesitter.install(parsers, { max_jobs = 4, summary = true }):wait(300000)
    treesitter.update(parsers, { max_jobs = 4, summary = true }):wait(300000)
  end,
  config = function()
    require("nvim-treesitter").setup()

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("langeoys-treesitter-highlight", { clear = true }),
      pattern = "*",
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end,
}
