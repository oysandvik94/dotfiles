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

M.init = function()
	for _, mark in ipairs(globalMarks) do
		vim.keymap.set("n", "'" .. mark, "'" .. mark .. "'\"", {})
	end
end

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
			local filename_only = vim.fn.fnamemodify(marks[item][4], ":t")

			local formatted_label = item .. " - " .. filename_only
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

M.lualine_global = function()
	local marks = M.get_mark_table()
	local lualine_marks = "󰐷 "

	for mark, fileinfo in pairs(marks) do
		local filename = fileinfo[4]

		local current_filename = vim.api.nvim_buf_get_name(0)

		local filename_only = vim.fn.fnamemodify(filename, ":t")
		local mark_string = string.format("%s: %s", mark, filename_only)

		if current_filename ~= vim.fn.expand(filename) then
			lualine_marks = lualine_marks .. mark_string .. " "
		end
	end

	return lualine_marks
end

M.is_marked = function(filename)
	local marks = M.get_mark_table()
	for _, fileinfo in pairs(marks) do
		if vim.fn.fnamemodify(fileinfo[4], ":t") == filename then
			return true
		end
	end

	return false
end

M.tabline_global_marks = function()
	local marks = M.get_mark_table()
	if vim.tbl_isempty(marks) then
		return ""
	end

	local tabline_marks = "󰐷 Marks: "
	local mark_items = {}

	for mark, fileinfo in pairs(marks) do
		local filename = fileinfo[4]
		local current_filename = vim.api.nvim_buf_get_name(0)
		local filename_only = vim.fn.fnamemodify(filename, ":t")

		-- Highlight current file's mark differently
		if current_filename == vim.fn.expand(filename) then
			table.insert(mark_items, string.format("%%#TabLineSel#%s:%s%%#TabLine#", mark, filename_only))
		else
			table.insert(mark_items, string.format("%s:%s", mark, filename_only))
		end
	end

	tabline_marks = tabline_marks .. table.concat(mark_items, " | ")
	return tabline_marks
end

M.setup_tabline = function()
	-- Custom tabline function that shows marks on the left and tabs on the right
	local function custom_tabline()
		local tabline = ""

		-- Left side: Global marks
		local marks_line = M.tabline_global_marks()
		if marks_line ~= "" then
			tabline = "%#TabLine# " .. marks_line .. " %#TabLineFill#"
		end

		-- Right side: Regular tabs (if any exist)
		local tab_count = vim.fn.tabpagenr('$')
		if tab_count > 1 then
			tabline = tabline .. "%="
			for i = 1, tab_count do
				local is_current = i == vim.fn.tabpagenr()
				local highlight = is_current and "%#TabLineSel#" or "%#TabLine#"
				local buf_name = vim.fn.bufname(vim.fn.tabpagebuflist(i)[1])
				local tab_name = buf_name ~= "" and vim.fn.fnamemodify(buf_name, ":t") or "[No Name]"

				tabline = tabline .. highlight .. string.format(" %d:%s ", i, tab_name)
			end
			tabline = tabline .. "%#TabLineFill#"
		else
			tabline = tabline .. "%="
		end

		return tabline
	end

	-- Set the tabline
	vim.o.tabline = "%!v:lua.require('langeoys.utils.marks').custom_tabline()"

	-- Store the custom tabline function globally so it can be called
	_G.custom_marks_tabline = custom_tabline

	-- Make custom_tabline available as a module function
	M.custom_tabline = custom_tabline
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
