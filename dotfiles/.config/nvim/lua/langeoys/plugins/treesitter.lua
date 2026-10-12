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
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    ts.setup()

    -- 1. Pre-install/update your default list on startup
    ts.install(parsers)

    -- 2. Auto-install missing parsers when opening new filetypes
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("langeoys-auto-install-treesitter", { clear = true }),
      pattern = "*",
      callback = function(args)
        local ft = vim.bo[args.buf].filetype
        if ft == "" then return end

        local lang = vim.treesitter.language.get_lang(ft) or ft

        -- Check if a parser for this language is already installed
        local ok = pcall(vim.treesitter.language.add, lang)
        if not ok then
          -- Missing parser detected: trigger background install
          ts.install({ lang }):next(function()
            -- Automatically start highlighting once compilation finishes
            vim.schedule(function()
              if vim.api.nvim_buf_is_valid(args.buf) then
                pcall(vim.treesitter.start, args.buf)
              end
            end)
          end)
        else
          -- Parser exists: start highlighting immediately
          pcall(vim.treesitter.start, args.buf)
        end
      end,
    })
  end,
}
