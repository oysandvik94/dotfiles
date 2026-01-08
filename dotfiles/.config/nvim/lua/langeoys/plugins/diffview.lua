return {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    config = function()
        require("codediff").setup({
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
