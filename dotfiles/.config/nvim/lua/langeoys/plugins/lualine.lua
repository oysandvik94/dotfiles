local function search_count()
	if vim.v.hlsearch == 0 then
		return
	end

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

return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		{ "nvim-tree/nvim-web-devicons", lazy = true },
		{ "letieu/harpoon-lualine" },
	},
	config = function()
		local custom_theme = require("lualine.themes.auto")
		custom_theme.normal.a.bg = os.getenv("COLOR_PRIMARY")
		custom_theme.normal.a.fg = os.getenv("COLOR_BACKGROUND")
		custom_theme.normal.b.bg = os.getenv("COLOR_TERTIARY")
		custom_theme.normal.b.fg = os.getenv("COLOR_BACKGROUND")
		custom_theme.normal.c.bg = "None"
		custom_theme.insert.c.bg = "None"
		custom_theme.visual.c.bg = "None"
		custom_theme.normal.c.fg = "#E6E1CF"

		local marks = require("langeoys.utils.marks")

		require("lualine").setup({
			options = {
				-- theme = "catppuccin",
				theme = custom_theme,
				component_separators = "",
				section_separators = { left = "", right = "" },
				globalstatus = true,
			},
			sections = {
				lualine_a = { { "mode", separator = { left = "", right = "" }, right_padding = 4 } },
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

							if marks.is_marked(str) then
								return "󰐷 " .. str
							end

							return str
						end,
					},
				},
				lualine_c = {
					{
						"active-global-marks",
						fmt = marks.lualine_global,
					},
				},
				lualine_x = { "diagnostics" },
				lualine_y = {
					{ "seach-count", fmt = search_count },
					{ "active-marks", fmt = marks.lualine },
					{ "macro-recording", fmt = show_macro_recording },
				}, -- Tmp objects
				-- lualine_z = { "branch", "diff" }, -- git
				lualine_z = {
					{ "diff" },
					{ "branch", separator = { right = "" }, left_padding = 2 },
				},
			},
		})
	end,
}
