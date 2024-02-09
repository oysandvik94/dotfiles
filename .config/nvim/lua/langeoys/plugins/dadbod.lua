local function db_completion()
    require("cmp").setup.buffer { sources = { { name = "vim-dadbod-completion" } } }
end

return {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
        { 'tpope/vim-dadbod',                     lazy = true },
        { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
    },
    cmd = {
        'DBUI',
        'DBUIToggle',
        'DBUIAddConnection',
        'DBUIFindBuffer',
    },
      init = function()
        vim.g.db_ui_save_location = vim.fn.stdpath "config" .. require("plenary.path").path.sep .. "db_ui"

        vim.api.nvim_create_autocmd("FileType", {
            pattern = {
                "sql",
            },
            command = [[setlocal omnifunc=vim_dadbod_completion#omni]],
        })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = {
                "sql",
                "mysql",
                "plsql",
            },
            callback = function()
                vim.schedule(db_completion)
            end,
        })

        vim.keymap.set('n', '<Leader>st', "<cmd>DBUIToggle<CR>", { desc = "Toggle db ui" })
    end
}
