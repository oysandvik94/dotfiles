return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        auto_open = true,
        auto_preview = false,
        position = "left"
    },
    config = function()
        require("trouble").setup({
            auto_preview = false,
        })
        -- Lua
        vim.keymap.set("n", "<leader>xx", function() require("trouble").toggle() end)
        vim.keymap.set("n", "<leader>xw", function() require("trouble").toggle("workspace_diagnostics") end)
        vim.keymap.set("n", "<leader>xd", function() require("trouble").toggle("document_diagnostics") end)
        vim.keymap.set("n", "<leader>xq", function() require("trouble").toggle("quickfix") end)
        vim.keymap.set("n", "<leader>xl", function() require("trouble").toggle("loclist") end)
        vim.keymap.set("n", "gR", function() require("trouble").toggle("lsp_references") end)
        vim.keymap.set("n", "]x", function()
            require("trouble").next({ skip_groups = true, jump = true });
        end)
        vim.keymap.set("n", "[x", function()
            require("trouble").previous({ skip_groups = true, jump = true });
        end)
    end
}
