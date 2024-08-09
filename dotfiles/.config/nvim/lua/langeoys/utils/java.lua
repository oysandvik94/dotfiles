local M = {}

local function find_file(partial_name)
	-- Use vim.fn.glob() to find matching files
	local files = vim.fn.glob("**/*" .. partial_name .. "*", false, true)

	-- If we found exactly one file, return it
	if #files == 1 then
		return files[1]
	elseif #files > 1 then
		-- If we found multiple files, let the user choose
		return vim.fn.inputlist(vim.list_extend({ "Multiple files found. Choose one:" }, files))
	else
		-- If we didn't find any files, return nil
		return nil
	end
end

M.navigate_to_input = function()
	vim.ui.input({ prompt = "Enter location (File.method:line): " }, function(input)
		if input then
			-- Split the input into file and line
			local file, line = input:match("([^:]+):(%d+)")

			if file and line then
				-- Convert line to number
				line = tonumber(line)

				-- Extract just the filename part (before the first dot)
				local file_name = file:match("([^.]+)")

				-- Find the full path of the file
				local full_path = find_file(file_name .. ".java")

				if full_path then
					-- Edit the file
					vim.cmd("edit " .. vim.fn.fnameescape(full_path))

					-- Move cursor to specified line
					vim.api.nvim_win_set_cursor(0, { line, 0 })
				else
					print("File not found: " .. file_name .. ".java")
				end
			else
				print("Invalid input format. Please use 'File.method:line'.")
			end
		end
	end)
end

return M
