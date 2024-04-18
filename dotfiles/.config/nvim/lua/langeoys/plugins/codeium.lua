return {
    'Exafunction/codeium.nvim',
    event = 'BufEnter',
    config = function()
        require("codeium").setup({
            enable_chat = true,
        })
        -- Change '<C-g>' here to any keycode you like.
        vim.keymap.set('i', '<C-g>', function() return vim.fn['codeium#Accept']() end, { expr = true })
        vim.keymap.set('i', '<C-;>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true })
        vim.keymap.set('i', '<C-,>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true })
        vim.keymap.set('i', '<C-x>', function() return vim.fn['codeium#Clear']() end, { expr = true })

        vim.keymap.set('n', '<leader>ce', function()
            vim.g.codeium_enabled = not vim.g.codeium_enabled
        end, { desc = "Toggle codeium" })
    end
}

-- return {
--     "Exafunction/codeium.nvim",
--     dependencies = {
--         "nvim-lua/plenary.nvim",
--         "hrsh7th/nvim-cmp",
--     },
--     config = function()
--         require("codeium").setup({
--             enable_chat = true,
--         })
--     end
-- }
