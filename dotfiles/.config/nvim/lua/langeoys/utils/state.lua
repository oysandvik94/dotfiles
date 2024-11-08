local M = {}

function get_state_file(state_key, cwd)
	local state_file = vim.fn.stdpath("data") .. "/"
	if cwd then
		local workspace_path = vim.fn.getcwd()
		local unique = vim.fn.fnamemodify(workspace_path, ":t") .. "_" .. vim.fn.sha256(workspace_path):sub(1, 8) ---@type string
		state_file = state_file .. unique .. "_"
	end

	state_file = state_file .. state_key .. ".json"
	return state_file
end
M.save_state = function(state_key, object, cwd)
	local Path = require("plenary.path")

	local state_file = get_state_file(state_key, cwd)

	Path:new(state_file):write(vim.fn.json_encode(object), "w")
end

M.get_state = function(state_key, cwd)
	local Path = require("plenary.path")

	local state_file = get_state_file(state_key, cwd)

	if Path:new(state_file):exists() then
		return vim.fn.json_decode(Path:new(state_file):read())
	end

	return nil
end

M.FORMAT_STATE = "autoformat"
M.COLOR_STATE = "color_scheme"

return M
