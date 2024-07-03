local function new_note()
	local ok, title = pcall(vim.fn.input, "Note title: ")
	if ok and title and title ~= "" then
		require("zk").new({ title = title })
	end
end

local function grep_note()
	local ok, search = pcall(vim.fn.input, "Search: ")
	if ok and search and search ~= "" then
		require("zk").notes({ sort = { "modified" }, match = search })
	end
end

return {
	"mickael-menu/zk-nvim",
	config = function()
		require("zk").setup({
			lsp = {
				-- `config` is passed to `vim.lsp.start_client(config)`
				config = {
					cmd = { "zk", "lsp" },
					name = "zk",
					on_attach = require("langeoys.utils.lsp").on_attach,
					-- etc, see `:h vim.lsp.start_client()`
				},

				-- automatically attach buffers in a zk notebook that match the given filetypes
				auto_attach = {
					enabled = true,
					filetypes = { "markdown" },
				},
			},
		})

		vim.keymap.set("x", "<leader>zf", ":'<,'>ZkMatch<CR>", { desc = "Zk Match" })
	end,
	keys = {
		{
			"<leader>zn",
			new_note,
			desc = "New note",
		},
		{
			"<leader>zct",
			":'<,'>ZkNewFromTitleSelection<CR>",
			mode = "x",
			desc = "New note from selection, but title",
		},
		{
			"<leader>zcc",
			":'<,'>ZkNewFromContentSelection<CR>",
			mode = "x",
			desc = "New note from selection",
		},
		{
			"<leader>zf",
			'<Cmd>ZkNotes { sort = { "modified" } }<CR>',
			desc = "Find notes",
		},
		{
			"<leader>zz",
			"<Cmd>ZkTags<CR>",
			desc = "Note tags",
		},
		{ "<leader>zi", "<Cmd>ZkInsertLink<CR>", desc = "Zk Insert link" },
		{
			"<leader>zi",
			":'<,'>ZkInsertLinkAtSelection<CR>",
			mode = "x",
			desc = "Zk Insert link at selection",
		},
		{ "<leader>zb", "<Cmd>ZkBacklinks<CR>", desc = "Zk Backlinks" },
		{ "<leader>zl", "<Cmd>ZkLinks<CR>", desc = "Zk Links" },
		{
			"<leader>z/",
			":'<,'>ZkMatch<CR>",
			mode = "x",
			desc = "Find in notes",
		},
		{
			"<leader>z/",
			grep_note,
			desc = "Find in notes",
		},
	},
}
