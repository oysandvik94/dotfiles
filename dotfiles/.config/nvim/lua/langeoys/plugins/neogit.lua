return {
    "NeogitOrg/neogit",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "sindrets/diffview.nvim",
        "ibhagwan/fzf-lua",
    },
    config = function()
        local neogit = require('neogit')

        local private_config = require("langeoys.utils.secret_git_config")
        local public_config = {}

        local combined_configs = vim.tbl_deep_extend('force', private_config, public_config)

        neogit.setup(combined_configs)

        vim.keymap.set("n", "<leader>gg", function() neogit.open() end)
    end
}
