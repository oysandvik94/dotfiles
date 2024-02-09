return {
    'karb94/neoscroll.nvim',
    enabled = true,
    config = function()
        require('neoscroll').setup({
                mappings = {'<C-u>', '<C-d>', 'zt', 'zz', 'zb'},
        })
    end
}
