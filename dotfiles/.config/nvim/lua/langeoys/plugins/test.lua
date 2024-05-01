return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"rcasia/neotest-java",
		"rouge8/neotest-rust"
	},
	config = function()
		require("neotest").setup({
			output = {
				open_on_run = false,
			},

			adapters = {
				require("neotest-java")({
					ignore_wrapper = false, -- whether to ignore maven/gradle wrapper
				}),
				require("neotest-rust")
			},
		})
		vim.keymap.set("n", "<leader>tn", function()
			require("neotest").run.run({})
		end)
		vim.keymap.set("n", "<leader>tl", function()
			require("neotest").run.run(vim.fn.expand("%"))
		end)
		vim.keymap.set("n", "<leader>tf", function()
			require("neotest").run.run(vim.fn.expand("%"))
		end)
		vim.keymap.set("n", "<leader>tl", function()
			require("neotest").run.run_last()
		end)
		vim.keymap.set("n", "<leader>to", ":Neotest output-panel<CR>G")
	end,
}
