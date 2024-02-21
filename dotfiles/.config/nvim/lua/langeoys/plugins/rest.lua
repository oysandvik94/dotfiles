return {
	"rest-nvim/rest.nvim",
	dependencies = { { "nvim-lua/plenary.nvim" } },
	config = function()
		local rest = require("rest-nvim")
		rest.setup({
			skip_ssl_verification = true,
		})

		vim.api.nvim_create_user_command("Http", function()
			vim.cmd.tabnew()
			local session_http = vim.fn.stdpath("data") .. "/session_http"
			vim.cmd.edit(session_http)
			vim.o.filetype = "http"
			vim.o.buftype = ""
		end, { desc = "Send HTTP request" })

		vim.api.nvim_create_user_command("HttpProject", function()
			vim.cmd.tabnew()
			local cwd_slug = vim.fn.getcwd():match("([^/]+)$")
			local session_http = vim.fn.stdpath("data") .. "/session_http_" .. cwd_slug
			vim.cmd.edit(session_http)
			vim.o.filetype = "http"
			vim.o.buftype = ""
		end, { desc = "HTTP workspace for this project" })

		vim.api.nvim_create_augroup("RestNvim", {})
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "http",
			callback = function()

				vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "<cmd>lua require('rest-nvim').run()<CR>", {})
				vim.api.nvim_buf_set_keymap(0, "n", "<leader>lr", "<cmd>lua require('rest-nvim').last()<CR>", {})
				vim.api.nvim_buf_set_keymap(0, "n", "<leader>ly", "<Plug>RestNvimPreview", {})
			end,
			group = "RestNvim",
		})
	end,
}
