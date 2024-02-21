return {
    "L3MON4D3/LuaSnip",
    config = function()
        local ls = require("luasnip")
        ls.config.set_config({
            history = true,
            updateevents = "TextChanged,TextChangedI",
            enable_autosnippets = true,
            ext_opts = {
                [require("luasnip.util.types").choiceNode] = {
                    active = {
                        virt_text = { { "<- choiceNode", "Error" } },
                    },
                },
            },

        })
        vim.keymap.set({ "i", "s" }, "<C-f>", function() ls.jump(1) end, { silent = true })
        vim.keymap.set({ "i", "s" }, "<C-b>", function() ls.jump(-1) end, { silent = true })
        vim.keymap.set({ "i", "s" }, "<C-l>", function()
            if ls.choice_active() then
                ls.change_choice(1)
            end
        end, { silent = true })

        vim.keymap.set("n", "<leader><leader>s", function()
            require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/lua/langeoys/snippets" })
        end, { silent = true })

        require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/lua/langeoys/snippets" })
    end
}
