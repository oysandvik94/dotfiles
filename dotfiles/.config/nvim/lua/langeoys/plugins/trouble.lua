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
		vim.keymap.set("n", "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>")
		vim.keymap.set("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>")
		vim.keymap.set("n", "<leader>xq", function()
			require("trouble").toggle("quickfix")
		end)
		vim.keymap.set("n", "gR", "<cmd>Trouble lsp_references toggle<CR>")
		vim.keymap.set("n", "gR", "<cmd>Trouble lsp_references toggle<CR>")
		vim.keymap.set("n", "gs", "<cmd>Trouble symbols toggle<CR>")
		vim.keymap.set("n", "]x", function()
			require("trouble").next({ skip_groups = true, jump = true })
		end)
		vim.keymap.set("n", "[x", function()
			require("trouble").previous({ skip_groups = true, jump = true })
		end)
	end,
}
