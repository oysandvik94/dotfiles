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
		local mark = vim.api.nvim_get_mark(v, {})
		if mark[1] ~= 0 then
			marks[v] = mark
		end
	end

	return marks
end

M.get_mark_list = function()
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

M.set_global_marks = function(marks)
	local bufnr = vim.api.nvim_create_buf(false, true)
	for k, v in pairs(marks) do
		local filename = vim.fn.expand(v[4])
		filename = "/home/oysandvik/dev/spring-chat.git/main/backend/pom.xml"
		filename = vim.fn.expand(filename)
		vim.api.nvim_buf_set_name(bufnr, filename)
		vim.api.nvim_buf_set_mark(bufnr, k, v[1], v[2], {})
	end
	vim.cmd("bd " .. bufnr)
end

M.clear_global_marks = function()
	for _, v in ipairs(globalMarks) do
		vim.api.nvim_del_mark(v)
	end
end

M.restore_wormtree_marks = function(absolute_path, absolute_prev_path)
	local state_utils = require("langeoys.utils.state")

	local stored_marks = state_utils.get_state(state_utils.MARK_STATE)

	local current_marks = M.get_mark_table()
	stored_marks[absolute_prev_path] = current_marks

	M.clear_global_marks()

	if stored_marks and stored_marks[absolute_path] then
		M.set_global_marks(stored_marks[absolute_path])
	end

    state_utils.save_state(state_utils.MARK_STATE, stored_marks)
end
return M
