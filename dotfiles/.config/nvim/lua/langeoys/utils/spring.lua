local M = {}

M.print_server_capabilities = function()
	local clients = vim.lsp.get_active_clients({ name = "jdtls" })
	if #clients == 0 then
		print("No active Java language server found")
		return
	end
	local client = clients[1]
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(vim.inspect(client.server_capabilities), "\n"))
	vim.api.nvim_command("vsplit")
	vim.api.nvim_win_set_buf(0, buf)
end

local function execute_command(command, arguments, callback)
	local params = {
		command = command,
		arguments = arguments,
	}

	vim.lsp.buf_request(0, "workspace/executeCommand", params, function(err, result, _, _)
		if err then
			vim.notify("Error executing command: " .. vim.inspect(err), vim.log.levels.ERROR)
			return
		end
		callback(result)
	end)
end

M.list_processes = function()
	M.print_server_capabilities()
	local uri = vim.uri_from_bufnr(0)
	execute_command("sts.livedata.listProcesses", { uri }, function(result)
		-- Handle the result here
		print(vim.inspect(result))
		-- You might want to display this in a more user-friendly way,
		-- perhaps using a floating window or telescope
	end)
end

return M
