local function search_count()
	local res = vim.fn.searchcount({ maxcount = 999, timeout = 500 })
	if res.total and res.total > 0 then
		return string.format("%s/%d %s", res.current, res.total, vim.fn.getreg("/"))
	end

	return ""
end

local function show_macro_recording()
	local recording_register = vim.fn.reg_recording()
	if recording_register == "" then
		return ""
	else
		return "Recording @" .. recording_register
	end
end

local function show_active_marks()
	local marks = vim.fn.execute("marks")
	marks = vim.split(marks, "\n")
	local active_marks = {}
	for index, line in ipairs(marks) do
		if index == 2 then
			goto continue
		end

		local activeMark = line:sub(1, 2):match("%l")
		if activeMark then
			table.insert(active_marks, activeMark)
		end
		::continue::
	end

	if #active_marks > 0 then
		return " " .. table.concat(active_marks, ",")
	else
		return nil
	end
end

return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		{ "nvim-tree/nvim-web-devicons", lazy = true },
		{ "letieu/harpoon-lualine" },
	},
	config = function()
		local custom_theme = require('lualine.themes.auto')
		custom_theme.normal.a.bg = '#f4dbd6'
		custom_theme.normal.a.fg = '#292c3c'
		custom_theme.normal.b.bg = '#232136'
		custom_theme.normal.b.fg = '#E6E1CF'
		custom_theme.normal.c.bg = 'None'
		custom_theme.insert.c.bg = 'None'
		custom_theme.visual.c.bg = 'None'
		custom_theme.normal.c.fg = '#E6E1CF'

		require("lualine").setup({
			sections = {
				lualine_a = { "mode" },
				lualine_b = {
					{
						"filename",
						path = 0,
						file_status = true,
						symbols = { modified = "  ", readonly = "  ", unnamed = "  " },
						--- @param str string
						fmt = function(str)
							--- @type string
							local fn = vim.fn.expand("%:~:.")

							if vim.startswith(fn, "jdt://") then
								return fn:gsub("?.*$", "")
							end
							return str
						end,
					},
				},
				lualine_c = { { "harpoon2", indicators = { '1', '2', '3', '4' }, active_indicators = { '[1]', '[2]', '[3]', '[4]' } } },
				lualine_x = { "diagnostics" },
				lualine_y = {
					{ "seach-count",     fmt = search_count },
					{ "active-marks",    fmt = show_active_marks },
					{ "macro-recording", fmt = show_macro_recording },
				},    -- Tmp objects
				lualine_z = { "branch", "diff" }, -- git
			},
			options = {
				theme                = custom_theme,
				component_separators = { left = "", right = "" },
				section_separators   = { left = "", right = "" },
				globalstatus         = false,
			},
		})
	end,
}
