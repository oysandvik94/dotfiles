return {
    'Exafunction/codeium.vim',
    event = 'BufEnter',
    config = function()
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
