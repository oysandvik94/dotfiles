-- Line numbers
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"

-- grep
vim.opt.grepprg = "rg --vimgrep"
vim.opt.grepformat = "%f:%l:%c:%m"

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "javascript", "python", "lua", "java" }, -- Add desired filetypes here
  callback = function()
    require("langeoys.folds")
  end,
})
require("langeoys.tabs")
-- Backup stuff
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Searching
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.keymap.set("n", "<esc>", "<cmd>nohlsearch<CR>")

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
  pattern = vim.fn.substitute(vim.fn.escape(pattern, "^$.*\\/~[]"), "\n", "\\n", "g")
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

vim.opt.list = false
vim.opt.listchars = { tab = "| ", trail = "·", nbsp = "␣" }
--

vim.highlight.priorities.semantic_tokens = 95
vim.o.whichwrap = "bs<>[]hl"
vim.opt.formatoptions:remove({ "c", "r", "o" }) -- don't insert the current comment leader automatically for auto-wrapping comments using 'textwidth', hitting <Enter> in insert mode, or hitting 'o' or 'O' in normal mode.

-- In your Neovim configuration:
vim.opt.exrc = true
vim.opt.secure = true
local workspace_path = vim.fn.getcwd()
local cache_dir = vim.fn.stdpath("data")
local unique_id = vim.fn.fnamemodify(workspace_path, ":t") ..
    "_" .. vim.fn.sha256(workspace_path):sub(1, 8) ---@type string
local shadafile = cache_dir .. "/myshada/" .. unique_id .. ".shada"

vim.opt.shadafile = shadafile

vim.opt.switchbuf = "usetab"
require("langeoys.utils.marks").init()

vim.filetype.add({
  extension = {
    las = "pipescript",
  },
})

-- spelling
vim.opt.spell = true
vim.opt.spelllang = { "nb", "en" }
