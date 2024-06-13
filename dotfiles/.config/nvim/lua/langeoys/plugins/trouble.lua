return {
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		auto_open = true,
		auto_preview = false,
		position = "left",
	},
	config = function()
		require("trouble").setup({
			auto_preview = false,
		})
		-- Lua
		vim.keymap.set("n", "<leader>xx", "<cmd>Trouble quickfix toggle<CR>")
		vim.keymap.set("n", "<leader>xw", "<cmd>Trouble diagnostics toggle focus=true<CR>")
		vim.keymap.set("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0 focus=true<CR>")
		vim.keymap.set("n", "<leader>xq", function()
			require("trouble").toggle("quickfix")
		end)
		vim.keymap.set("n", "grr", "<cmd>Trouble lsp_references toggle focus=true pinned=true<CR>")
		vim.keymap.set("n", "<leader>xs", "<cmd>Trouble symbols toggle<CR>")
		vim.keymap.set("n", "]x", function()
			require("trouble").next({ skip_groups = true, jump = true })
		end)
		vim.keymap.set("n", "[x", function()
			require("trouble").prev({ skip_groups = true, jump = true })
		end)
	end,
}
