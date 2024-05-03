return {
    'stevearc/overseer.nvim',
    config = function()
        require('overseer').setup()

        vim.keymap.set("n", "<leader>o", "<cmd>OverseerRun<CR>")
    end
}
