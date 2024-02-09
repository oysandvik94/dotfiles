local function search_count()
	local res = vim.fn.searchcount({ maxcount = 999, timeout = 500 })
	if res.total > 0 then
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

	return "ok"
end

return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		{ "nvim-tree/nvim-web-devicons", lazy = true },
	},
	config = function()
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
				lualine_c = { "progress"},
				lualine_x = { "diagnostics" },
				lualine_y = {
					{ "seach-count", fmt = search_count },
					{ "active-marks", fmt = show_active_marks },
					{ "macro-recording", fmt = show_macro_recording },
				}, -- Tmp objects
				lualine_z = { "branch", "diff" }, -- git
			},
			options = {
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				globalstatus = false,
			},
		})
	end,
}
