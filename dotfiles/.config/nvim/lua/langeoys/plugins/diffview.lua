return {
    "esmuellert/vscode-diff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    config = function()
        require("vscode-diff").setup({
            diff = {
                disable_inlay_hints = true
            },
            keymaps = {
                view = {
                    next_hunk = "]h", -- Jump to next change
                    prev_hunk = "[h", -- Jump to previous change
                },
            }
        })
    end,
}
