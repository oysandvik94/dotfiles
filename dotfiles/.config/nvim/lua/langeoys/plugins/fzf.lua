local dap_ui_picker = function()
	local dap_ui = require("dapui")
	local fzf = require("fzf-lua")

	local items = { "scopes", "breakpoints", "stacks", "watches", "repl", "console" }

	fzf.fzf_exec(items, {
		actions = {
			["default"] = function(selected)
				dap_ui.float_element(selected[1], { enter = true })
			end,
		},
	})
end

local harpoon_picker = function()
	local fzf = require("fzf-lua")
	local harpoon = require("harpoon")

	local harpoon_files = harpoon:list()
	local file_paths = {}
	for idx, item in ipairs(harpoon_files.items) do
		local filename_table = vim.split(item.value, "/")
		local filename = filename_table[#filename_table]
		local file = require("fzf-lua").make_entry.file(filename, { file_icons = true, color_icons = true })
		table.insert(file_paths, idx .. ": " .. file)
	end

	fzf.fzf_exec(file_paths, {
		prompt = "Harpoon> ",
		actions = {
			["default"] = function(selected)
				local harpoon_index = vim.split(selected[1], ": ")[1]
				harpoon:list():select(tonumber(harpoon_index))
			end,
		},
		fn_transform = function(x)
			P("heisann")
			return require("fzf-lua").make_entry.file(x, { file_icons = true, color_icons = true })
		end,
	})
end

--- @see https://github.com/ibhagwan/fzf-lua/wiki/Advanced#preview-overview
local function folders()
	local fzflua = require("fzf-lua")

	local cmd = string.format([[fd --color always --hidden --exclude .git --type directory --max-depth 8]], 8)
	local has_exa = vim.fn.executable("eza") == 1

	local opts = {}
	opts.prompt = "󰥨  Folders❯ "
	opts.cmd = cmd
	opts.cwd_header = true
	opts.cwd_prompt = true
	opts.toggle_ignore_flag = "--no-ignore-vcs"
	opts.winopts = {
		fullscreen = false,
	}
	opts.fzf_opts = {
		["--preview-window"] = "nohidden,down,50%",
		["--preview"] = fzflua.shell.raw_preview_action_cmd(function(items)
			if has_exa then
				return string.format(
					"cd %s ; eza --color=always --icons=always --group-directories-first -a %s",
					nil,
					items[1]
				)
			end
			return string.format("cd %s ; ls %s", nil, items[1])
		end),
	}

	opts.actions = {
		["default"] = function(selected, selected_opts)
			require("oil").open(selected[1])
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
			files = {
				formatter = "path.filename_first",
			},
			defaults = {
				copen = function()
					require("trouble").toggle("quickfix")
				end,
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
				prompt = "Colorschemes❯ ",
				live_preview = true, -- apply the colorscheme on preview?
				winopts = { height = 0.55, width = 0.30 },
				ignore_patterns = {
					"^delek$",
					"^darkblue$",
					"^evening$",
					"^morning$",
					"^blue$",
					"^default$",
					"^delek$",
					"^koehler$",
					"^pablo$",
					"^ron$",
					"^shine$",
				},
				cb_exit = function(res)
					require("langeoys.utils.state").save_state("colorscheme", res[2])
				end,
			},
		})
		vim.keymap.set("n", "<leader>/", "<cmd>lua require('fzf-lua').files() <CR>", { silent = true })
		vim.keymap.set("n", "<leader>fm", function()
			folders()
		end, { silent = true })
		vim.keymap.set("n", "<leader>ft", "<cmd>lua require('fzf-lua').tags()<CR>", { silent = true })
		vim.keymap.set(
			"n",
			"<leader>fg",
			-- "<cmd>lua require('fzf-lua').live_grep_glob({rg_opts = \"--column --hidden --line-number --no-heading --color=always --smart-case --max-columns=4096 -g '!*.git/*' -e\"})<CR>",
			"<cmd>lua require('fzf-lua').live_grep_glob({rg_opts = \"--hidden --line-number --smart-case --sort-files -g '!*.git/*'\"})<CR>",
			{ silent = true }
		)
		vim.keymap.set("v", "<leader>fg", "<cmd>lua require('fzf-lua').grep_visual()<CR>", { silent = true })
		vim.keymap.set("n", "<leader>fl", "<cmd>lua require('fzf-lua').resume()<CR>", { silent = true })
		vim.keymap.set("n", "<leader>fz", "<cmd>lua require('fzf-lua').builtin()<CR>", { silent = true })
		vim.keymap.set("n", "<leader>fh", "<cmd>lua require('fzf-lua').help_tags()<CR>", { silent = true })
		vim.keymap.set("n", "<leader>fi", dap_ui_picker, {})
		vim.keymap.set("n", "<leader>fc", "<cmd>lua require('fzf-lua').commands()<CR>", {})
		vim.keymap.set("n", "<leader>fw", "<cmd>lua require('fzf-lua').grep_cword()<CR>", {})
		vim.keymap.set("n", "<leader>fW", "<cmd>lua require('fzf-lua').grep_cWORD()<CR>", {})
		vim.keymap.set("n", "<C-e>", harpoon_picker, { desc = "Open harpoon window" })
	end,
}
