local M = {}

local globalMarks = {
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
}

M.get_mark_table = function()
	local marks = {}
	for _, v in ipairs(globalMarks) do
		local mark = vim.api.nvim_get_mark(v, {}) ---@type vim.api.keyset.get_mark
		if mark[1] ~= 0 then
			marks[v] = mark
		end
	end

	return marks
end

M.select_mark = function()
	local marks = M.get_mark_table()

	local option_labels = {}
	for key, _ in pairs(marks) do
		table.insert(option_labels, key)
	end

	vim.ui.select(option_labels, {
		prompt = "Select mark",
		format_item = function(item)
			local formatted_label = item .. " - " .. marks[item][4]
			return formatted_label
		end,
	}, function(mark)
		if mark then
			vim.cmd("normal! '" .. mark)
		end
	end)
end

M.clear_global_marks = function()
	for _, v in ipairs(globalMarks) do
		vim.api.nvim_del_mark(v)
	end
end

-- {
--   A = { 220, 0, 44, "~/dev/bergen/intranett/intranett-appserver/tomcat/src/main/java/no/kommune/bergen/intranett/tomcat/Main.java" },
--   R = { 222, 0, 44, "~/dev/bergen/intranett/intranett-appserver/tomcat/src/main/java/no/kommune/bergen/intranett/tomcat/Main.java" },
--   S = { 16, 34, 0, "/home/oystein.sandvik/dev/bergen/ks-min-kommune-sync/src/main/frontend/src/services/AdminService.ts" }
-- }

M.lualine_global = function()
	local marks = M.get_mark_table()
	local lualine_marks = "󰐷 "

	for mark, fileinfo in pairs(marks) do
		local filename = fileinfo[4]

		local current_filename = vim.api.nvim_buf_get_name(0)

		local filename_only = vim.fn.fnamemodify(filename, ":t")
		local mark_string = string.format("%s: %s", mark, filename_only)

		if current_filename == vim.fn.expand(filename) then
			mark_string = string.format("[%s]", mark_string)
		end

		lualine_marks = lualine_marks .. mark_string .. " "
	end

	return lualine_marks
end

M.lualine = function()
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

return M
