return {
	"pmizio/typescript-tools.nvim",
	enabled = false,
	dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
	opts = {},
	config = function()
		require("typescript-tools").setup({
			complete_function_calls = true,
			on_attach = function()
				vim.keymap.set(
					"n",
					"<leader>lo",
					[[
                <cmd>TSToolsAddMissingImports<cr>
                <cmd>TSToolsRemoveUnusedImports<cr>
                <cmd>TSToolsOrganizeImports<cr>
                ]],
					{ desc = "Organize Imports" }
				)
				vim.keymap.set("n", "<leader>lO", "<cmd>TSToolsSortImports<cr>", { desc = "Sort Imports" })
				vim.keymap.set("n", "<leader>lu", "<cmd>TSToolsRemoveUnused<cr>", { desc = "Removed Unused" })
				vim.keymap.set(
					"n",
					"<leader>lz",
					"<cmd>TSToolsGoToSourceDefinition<cr>",
					{ desc = "Go To Source Definition" }
				)
				vim.keymap.set(
					"n",
					"<leader>lR",
					"<cmd>TSToolsRemoveUnusedImports<cr>",
					{ desc = "Removed Unused Imports" }
				)
				vim.keymap.set("n", "<leader>lF", "<cmd>TSToolsFixAll<cr>", { desc = "Fix All" })
				vim.keymap.set("n", "<leader>lA", "<cmd>TSToolsAddMissingImports<cr>", { desc = "Add Missing Imports" })
			end,
		})
	end,
}
