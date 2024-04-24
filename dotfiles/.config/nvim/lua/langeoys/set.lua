-- Line numbers
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"

-- Indenting
vim.opt.colorcolumn = "99"
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
function TabsOrSpaces()
	-- Determines whether to use spaces or tabs on the current buffer.
	if vim.fn.getfsize(vim.fn.bufname("%")) > 256000 then
		-- File is very large, just use the default.
		return
	end

	local numTabs = #vim.fn.filter(vim.fn.getbufline(vim.fn.bufname("%"), 1, 250), 'v:val =~ "^\t"')
	local numSpaces = #vim.fn.filter(vim.fn.getbufline(vim.fn.bufname("%"), 1, 250), 'v:val =~ "^ "')

	if numTabs > numSpaces then
		vim.api.nvim_buf_set_option(0, "expandtab", false)
	else
		vim.api.nvim_buf_set_option(0, "expandtab", true)
	end
end

-- Call the function after opening a buffer
local TabsOrSpacer_group = vim.api.nvim_create_augroup("TabsOrSpacer", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		TabsOrSpaces()
	end,
	group = TabsOrSpacer_group,
	pattern = "*",
})

vim.api.nvim_create_user_command("TabsOrSpaces", function()
	TabsOrSpaces()
end, {})

-- Backup stuff
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Searching
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- handle unpack deprecation
table.unpack = table.unpack or unpack
local function get_visual()
  local _, ls, cs = table.unpack(vim.fn.getpos("v"))
  local _, le, ce = table.unpack(vim.fn.getpos("."))
  return vim.api.nvim_buf_get_text(0, ls - 1, cs - 1, le - 1, ce, {})
end

vim.keymap.set("v", "<C-r>", function()
  local pattern = table.concat(get_visual())
  -- escape regex and line endings
  pattern =
    vim.fn.substitute(vim.fn.escape(pattern, "^$.*\\/~[]"), "\n", "\\n", "g")
  -- send substitute command to vim command line
  vim.api.nvim_input("<Esc>:%s/" .. pattern .. "//g<Left><Left>")
end)


-- Colors?
vim.opt.termguicolors = true

-- Scrollstuff
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes:1"
vim.opt.isfname:append("@-@")

-- Performance
vim.opt.updatetime = 50

vim.g.mapleader = " "

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

-- wrap
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.wrap = true
vim.opt.showbreak = "↳ "
-- vim.filetype.indent = true

-- Cmdheight 0
vim.opt.cmdheight = 0

-- Automatically update files when changed outside of vim
vim.cmd([[set autoread]])
vim.cmd([[autocmd FocusGained * checktime]])
