local dap_ui_picker = function()
    local dap_ui = require("dapui")
    local fzf = require("fzf-lua")

    local items = { "scopes", "breakpoints", "stacks", "watches", "repl", "console" }

    fzf.fzf_exec(items, {
        actions = {
            ["default"] = function(selected)
                dap_ui.float_element(selected[1], { enter = true })
            end
        }
    })
end

local function files(opts)
    opts = opts or {}

    local fzflua = require('fzf-lua')

    local cmd = nil
    if vim.fn.executable('fd') == 1 then
        local fzfutils = require('fzf-lua.utils')
        -- fzf-lua.defaults#defaults.files.fd_opts
        cmd = string.format(
            [[fd --color=never --type f --hidden --follow --exclude .git -x printf "{}: {/} %s\n"]],
            fzfutils.ansi_codes.grey('{//}')
        )
        opts.fzf_opts = {
            -- process ansi colors
            ['--ansi'] = '',
            ['--with-nth'] = '2..',
            ['--delimiter'] = '\\s',
            ['--tiebreak'] = 'begin,index',
        }
    end
    opts.cmd = cmd

    opts.winopts = {
        fullscreen = false,
        height = 0.90,
        width = 1,
    }
    opts.ignore_current_file = true

    return fzflua.files(opts)
end

--- @see https://github.com/ibhagwan/fzf-lua/wiki/Advanced#preview-overview
local function folders()
    local fzflua = require('fzf-lua')

    local cmd = string.format([[fd --color always --hidden --exclude .git --type directory --max-depth 8]],
        8)
    local has_exa = vim.fn.executable('eza') == 1

    local opts = {}
    opts.prompt = '󰥨  Folders❯ '
    opts.cmd = cmd
    opts.cwd_header = true
    opts.cwd_prompt = true
    opts.toggle_ignore_flag = '--no-ignore-vcs'
    opts.winopts = {
        fullscreen = false,
    }
    opts.fzf_opts = {
        ['--preview-window'] = 'nohidden,down,50%',
        ['--preview'] = fzflua.shell.raw_preview_action_cmd(function(items)
            if has_exa then
                return string.format(
                    'cd %s ; eza --color=always --icons=always --group-directories-first -a %s',
                    nil,
                    items[1]
                )
            end
            return string.format('cd %s ; ls %s', nil, items[1])
        end),
    }

    opts.actions = {
        ['default'] = function(selected, selected_opts)
            require 'oil'.open(selected[1])
        end,
    }

    return fzflua.fzf_exec(cmd, opts)
end


return {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        -- calling `setup` is optional for customization
        require("fzf-lua").setup({
            defaults = {
                copen = function()
                    require("trouble").toggle("quickfix")
                end
            },
            winopts = {
                preview = {
                    layout = "vertical",
                    vertical = "up",
                },
            },
            keymap = {
                fzf = {
                    ["ctrl-q"] = "select-all+accept",
                },
                builtin = {
                    ["<C-d>"] = "preview-page-down",
                    ["<C-u>"] = "preview-page-up",
                },
            },
            colorschemes = {
                prompt          = "Colorschemes❯ ",
                live_preview    = true, -- apply the colorscheme on preview?
                winopts         = { height = 0.55, width = 0.30 },
                ignore_patterns = { "^delek$", "^darkblue$", "^evening$", "^morning$", "^blue$", "^default$", "^delek$", "^koehler$", "^pablo$", "^ron$", "^shine$" },
                cb_exit         = function(res)
                    require("langeoys.utils.state").save_state("colorscheme", res[2])
                end
            },
        })
        vim.keymap.set("n", "<leader>/", function() files() end, { silent = true })
        vim.keymap.set("n", "<leader>fm", function() folders() end, { silent = true })
        vim.keymap.set("n", "<leader>ft", "<cmd>lua require('fzf-lua').tags()<CR>", { silent = true })
        vim.keymap.set("n", "<leader>fg",
            "<cmd>lua require('fzf-lua').live_grep_glob({rg_opts = \"--column --hidden --line-number --no-heading --color=always --smart-case --max-columns=4096 -g '!*.git/*' -e\"})<CR>",
            { silent = true })
        vim.keymap.set("v", "<leader>fg", "<cmd>lua require('fzf-lua').grep_visual()<CR>", { silent = true })
        vim.keymap.set("n", "<leader>fl", "<cmd>lua rquire('fzf-lua').resume()<CR>", { silent = true })
        vim.keymap.set("n", "<leader>fz", "<cmd>lua require('fzf-lua').builtin()<CR>", { silent = true })
        vim.keymap.set("n", "<leader>fh", "<cmd>lua require('fzf-lua').help_tags()<CR>", { silent = true })
        vim.keymap.set("n", "<leader>fd", dap_ui_picker, {})
        vim.keymap.set("n", "<leader>fc", "<cmd>lua require('fzf-lua').commands()<CR>", {})
        vim.keymap.set("n", "<leader>fs", "<cmd>lua require('fzf-lua').blines()<CR>", {})
    end
}
