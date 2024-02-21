return {
    "folke/zen-mode.nvim",
    config = function()
        vim.keymap.set("n", "<leader>zm", ":ZenMode<CR>", { noremap = true, silent = true })
    end,
    opts = {
        window = {
            backdrop = 1,
            width = 0.7, -- width of the Zen window
        },
        plugins = {
            options = {
                showcmd = true             -- disables the command in the last line of the screen
            },
            alacritty = {
                enabled = false,
                font = "20", -- font size
            },
        },
    }
}
