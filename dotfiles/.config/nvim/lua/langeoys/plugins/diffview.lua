return {
    'sindrets/diffview.nvim',
    config = function()
        local actions = require("diffview.actions")
        require('diffview').setup({
            keymaps = {
                file_panel = {
                    { "n", "<c-u>", actions.scroll_view(-0.25), { desc = "Scroll the view up" } },
                    { "n", "<c-d>", actions.scroll_view(0.25),  { desc = "Scroll the view down" } },
                }
            }
        })

        vim.keymap.set("n", "<leader>cf", ":DiffviewFileHistory %<CR>")
    end
}
