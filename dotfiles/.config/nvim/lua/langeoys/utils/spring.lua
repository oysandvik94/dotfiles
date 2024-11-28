local M = {}

M.print_server_capabilities = function()
	local clients = vim.lsp.get_active_clients({ name = "spring-boot" })
	if #clients == 0 then
		print("No active Java language server found")
		return
	end
	local client = clients[1]
	vim.print(client.server_capabilities)
end

local function execute_command(command, arguments, callback)
	local params = {
		command = command,
		arguments = arguments,
	}

	vim.lsp.buf_request(0, "workspace/executeCommand", params, function(err, result, ok, haha)
		if err then
			vim.notify("Error executing command: " .. vim.inspect(err), vim.log.levels.ERROR)
			return
		end

		vim.print("it works!")
		vim.print(err)
		vim.print(result)
		vim.print(ok)
		vim.print(haha)
		callback(result)
	end)
end

--     commands = { "sts.vscode-spring-boot.codeAction", "sts.vscode-spring-boot.commandList", "sts/boot/props-to-yaml", "sts/rewrite/reload", "sts/
-- boot/yaml-to-props", "sts/livedata/configure/logLevel", "sts/livedata/remoteConnect", "sts/upgrade/spring-boot", "sts/livedata/connect", "sts/mod
-- ulith/projects", "sts/livedata/getLoggers", "sts/livedata/listProcesses", "sts/livedata/get", "sts/common-properties/reload", "sts/rewrite/list",
--  "sts/livedata/localRemove", "sts.vscode-spring-boot.resolve.completion.edit.6a9916a2-9cd8-48d0-b322-dd87ad52186c", "sts/livedata/get/metrics", "
-- sts/show/document", "sts/spring-boot/executableBootProjects", "sts/livedata/listConnected", "sts/livedata/refresh/metrics", "sts/rewrite/execute"
-- , "sts/rewrite/sublist", "sts/livedata/disconnect", "sts/modulith/metadata/refresh", "sts/livedata/localAdd", "sts/livedata/refresh", "sts.vscode
-- -spring-boot.enableClasspathListening" },

M.list_processes = function()
	local uri = vim.uri_from_bufnr(0)
	execute_command("sts.livedata.listProcesses", { uri }, function(result)
		-- Handle the result here
		vim.print("her er resultatet")
		vim.print(vim.inspect(result))
		-- You might want to display this in a more user-friendly way,
		-- perhaps using a floating window or telescope
	end)
end

return M
