vim.g.mapleader = " "

-- Move lines with V and J in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor at start of line when using J
vim.keymap.set("n", "J", "mzJ`z")

-- Navigate through wraps
vim.keymap.set("n", "<up>", "v:count == 0 ? 'gk' : 'k'", { noremap = true, expr = true, silent = true })
vim.keymap.set("n", "<down>", "v:count == 0 ? 'gj' : 'j'", { noremap = true, expr = true, silent = true })

-- Dont replace register when wasting over selection
vim.keymap.set("x", "<leader>p", "p")
vim.keymap.set("x", "p", [["_dP]])

-- Copy to system clipboard with leader y
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({ "n", "v" }, "<leader>p", [["+p]])
vim.keymap.set("n", "<leader>p", [["+P]])

-- Spelling
vim.keymap.set("i", "<c-z>", "<c-g>u<Esc>[s1z=`]a<c-g>u",
	{ noremap = true, desc = "Fix last spelling mistake in insert mode" })

-- Back and forths
vim.keymap.set("n", "]q", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "[q", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "]t", "<cmd>tabnext<CR>")
vim.keymap.set("n", "[t", "<cmd>tabprev<CR>")
vim.keymap.set("n", "]f", "zj")
vim.keymap.set("n", "[f", "zk")

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>")

-- Splits
vim.keymap.set("n", "<C-W>s", "<cmd>split<CR><C-w>w")
vim.keymap.set("n", "<C-W>v", "<cmd>vsplit<CR><C-w>w")

-- Insert semicolon
vim.keymap.set("i", "<C-]>", "<esc>A;<esc>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader><leader>x", "<cmd>w<CR><cmd> so %<CR>", { silent = true })

-- color
vim.api.nvim_create_user_command("PrintColor", function()
	local fileName = vim.fn.stdpath("data") .. "/colorscheme"
	local file = io.open(fileName, "r")
	if file then
		local color = file:read()
		print(color)
		file:close()
	end
end, { nargs = 0 })

vim.keymap.set("n", "<leader>mf", require("langeoys.utils.marks").select_mark, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>mc", require("langeoys.utils.marks").clear_global_marks, { noremap = true, silent = true })

vim.keymap.set(
	"n",
	"<leader><leader>d",
	"<cmd>!/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME add %<CR>",
	{ silent = true }
)

vim.keymap.set("n", "ycc", "yygccp", { remap = true })
