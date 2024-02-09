return {
    'ThePrimeagen/harpoon',
    config = function()
        require("harpoon").setup({
            tabline = false,
        })

        local mark = require("harpoon.mark")
        local ui = require("harpoon.ui")

        vim.keymap.set("n", "<leader>a", mark.add_file, { desc = "Add file to harpoon list" })
        vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu, { desc = "Toggle harpoon window" })

        vim.keymap.set("n", "<A-1>", function() ui.nav_file(1) end, { desc = "Go to first harpooned file" })
        vim.keymap.set("n", "<A-2>", function() ui.nav_file(2) end, { desc = "Go to second harpooned file" })
        vim.keymap.set("n", "<A-3>", function() ui.nav_file(3) end, { desc = "Go to third harpooned file" })
        vim.keymap.set("n", "<A-4>", function() ui.nav_file(4) end, { desc = "Go to fourth harpooned file" })

        vim.cmd('highlight! HarpoonInactive guibg=NONE guifg=#6E6A86')
        vim.cmd('highlight! HarpoonActive guibg=NONE guifg=#F6C177')
        vim.cmd('highlight! HarpoonNumberActive guibg=NONE guifg=#EA9A97')
        vim.cmd('highlight! HarpoonNumberInactive guibg=NONE guifg=#6E6A86')
        vim.cmd('highlight! TabLineFill guibg=NONE guifg=#F6C177')
    end
}
