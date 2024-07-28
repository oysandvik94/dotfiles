return {
	"stevearc/oil.nvim",
	config = function()
		require("oil").setup({
			default_file_explorer = true,
			columns = {
				"icon",
			},
			keymaps = {
				-- This binds are used by tmux navigator
				["<C-h>"] = false,
				["<C-l>"] = false,
				["<C-r>"] = "actions.refresh",
			},
			view_options = {
				show_hidden = true,
				is_always_hidden = function(name, bufnr)
					return (name == "..")
				end,
			},
			skip_confirm_for_simple_edits = true,
		})
		vim.keymap.set("n", "-", require("oil").open, { desc = "Open parent directory" })
	end,
}
