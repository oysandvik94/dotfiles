return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup()

        vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
        vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

        vim.keymap.set("n", "<A-a>", function() harpoon:list():select(1) end)
        vim.keymap.set("n", "<A-r>", function() harpoon:list():select(2) end)
        vim.keymap.set("n", "<A-s>", function() harpoon:list():select(3) end)
        vim.keymap.set("n", "<A-t>", function() harpoon:list():select(4) end)

        vim.keymap.set("n", "<leader><A-a>", function() harpoon:list():replace_at(1) end)
        vim.keymap.set("n", "<leader><A-r>", function() harpoon:list():replace_at(2) end)
        vim.keymap.set("n", "<leader><A-s>", function() harpoon:list():replace_at(3) end)
        vim.keymap.set("n", "<leader><A-t>", function() harpoon:list():replace_at(4) end)

        -- Toggle previous & next buffers stored within Harpoon list
        vim.keymap.set("n", "]h", function() harpoon:list():prev() end)
        vim.keymap.set("n", "[h", function() harpoon:list():next() end)
    end
}
