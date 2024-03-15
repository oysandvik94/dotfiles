vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			vim.api.nvim_win_set_cursor(0, mark)
		end
	end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "*.keymap", command = "set filetype=c" })

local function write_commit_prefix()
    -- Run the Git command to get the current branch name
    local handle = io.popen("git branch --show-current")
    local branch = handle:read("*a")
    handle:close()

    -- Trim whitespace from the branch name
    branch = string.gsub(branch, "^%s*(.-)%s*$", "%1")

    -- Check if the branch name contains 'UT-XXXX'
    local ut_number = string.match(branch, "UT%-%d%d%d%d")
    if ut_number then
        -- Insert 'UT-XXXX: ' at the beginning of the buffer
        local insert_text = ut_number .. ": "
        vim.api.nvim_buf_set_lines(0, 0, 0, false, {insert_text})


		-- put the cursor in insert mode at the end of the line
		vim.api.nvim_feedkeys("A", "n", true);
    end
end

-- Set up the autocommand for NeogitCommitMessage filetype
vim.api.nvim_create_autocmd("FileType", {
    pattern = "NeogitCommitMessage",
    callback = write_commit_prefix
})

