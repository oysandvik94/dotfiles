return {
    'stevearc/conform.nvim',
    opts = {},
    config = function()
        require("conform").formatters.memes = {
            command = "google-java-format",
            args = { "-a", "-" },
        }

        require("conform").formatters.customxmlformat = {
            command = "xmlformat",
            args = { "--indent", "4", "--overwrite", "-" },
        }

        require("conform").setup({
            formatters_by_ft = {
                lua             = { "stylua" },
                -- Conform will run multiple formatters sequentially
                python          = { "isort", "black" },
                -- Use a sub-list to run only the first available formatter
                -- java            = { "memes" },
                javascript      = { "prettier" },
                typescript      = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                css             = { "prettier" },
                xml             = { "customxmlformat" },
                html            = { "prettier" },
                markdown        = { "prettier" },
                bash            = { "shfmt" },
                sh            = { "shfmt" }
            },
        })


        vim.api.nvim_create_user_command("Format", function(args)
            local range = nil
            if args.count ~= -1 then
                local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
                range = {
                    start = { args.line1, 0 },
                    ["end"] = { args.line2, end_line:len() },
                }
            end
            require("conform").format({ async = true, lsp_fallback = true, range = range })
        end, { range = true })

        vim.keymap.set({ 'n' }, "<leader>lf", ":Format<CR>", { desc = "Format file according to formatter" })
        vim.keymap.set({ 'x', 'v'}, "<leader>lf", ":'<,'>Format<CR>", { desc = "Format file according to formatter" })
    end
}
