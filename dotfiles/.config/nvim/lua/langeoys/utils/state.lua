local M = {}

M.save_state = function(state_key, object)
    P("saving state " .. state_key)
    P(object)
	local Path = require("plenary.path")

	local state_file = vim.fn.stdpath("data") .. "/" .. state_key .. ".json"

	Path:new(state_file):write(vim.fn.json_encode(object), "w")
end

M.get_state = function(state_key)
    local Path = require("plenary.path")

    local state_file = vim.fn.stdpath("data") .. "/" .. state_key .. ".json"

    if Path:new(state_file):exists() then
        return vim.fn.json_decode(Path:new(state_file):read())
    end

    return {}
end

M.MARK_STATE = "global_marks"
M.COLOR_STATE = "color_scheme"


return M
