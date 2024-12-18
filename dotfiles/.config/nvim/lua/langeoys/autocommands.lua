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
    vim.api.nvim_buf_set_lines(0, 0, 1, false, { insert_text })

    -- put the cursor in insert mode at the end of the line
  end
  vim.api.nvim_feedkeys("A", "n", true)
end

-- Set up the autocommand for NeogitCommitMessage filetype
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = write_commit_prefix,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("persistence", { clear = true }),
  callback = function()
    if vim.fn.argc() == 0 and vim.bo.filetype ~= "man" then
      require("persistence").load()
    end
  end,
  nested = true,
})
