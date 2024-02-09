return {
    "rgroli/other.nvim",
    config = function()
        require("other-nvim").setup({
            mappings = {
                "livewire",
                "angular",
                "laravel",
                "rails",
                "golang",
            },
        })

        vim.api.nvim_set_keymap("n", "<leader>oo", "<cmd>:Other<CR>", { noremap = true, silent = true })
        vim.api.nvim_set_keymap("n", "<leader>oh", "<cmd>:OtherSplit<CR>", { noremap = true, silent = true })
        vim.api.nvim_set_keymap("n", "<leader>ov", "<cmd>:OtherVSplit<CR>", { noremap = true, silent = true })
        vim.api.nvim_set_keymap("n", "<leader>oc", "<cmd>:OtherClear<CR>", { noremap = true, silent = true })

        vim.api.nvim_set_keymap("n", "<leader>oac", "<cmd>:Other component<CR>", { noremap = true, silent = true })
        vim.api.nvim_set_keymap("n", "<leader>oah", "<cmd>:Other view<CR>", { noremap = true, silent = true })
    end
}
