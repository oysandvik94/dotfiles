return {
	"NeogitOrg/neogit",
	enabled = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"sindrets/diffview.nvim",
		"ibhagwan/fzf-lua",
	},
	config = function()
		local neogit = require("neogit")

		if pcall(require, "langeoys.utils.secret_git_config") then
			local private_config = require("langeoys.utils.secret_git_config")
			local public_config = {
				integrations = {
					fzf_lua = true,
					diffview = true,
				},
			}

			local combined_configs = vim.tbl_deep_extend("force", private_config, public_config)

			neogit.setup(combined_configs)
		else
			neogit.setup({})
		end

		vim.keymap.set("n", "<leader>gg", function()
			neogit.open()
		end)
	end,
}
