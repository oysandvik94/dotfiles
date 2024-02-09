return {
	"vuki656/package-info.nvim",
	dependencies = "MunifTanjim/nui.nvim",
	config = function()
		require("package-info").setup()
		vim.api.nvim_set_keymap(
			"n",
			"<leader>np",
			"<cmd>lua require('package-info').change_version()<cr>",
			{ silent = true, noremap = true }
		)
		vim.api.nvim_set_keymap(
			"n",
			"<leader>nd",
			"<cmd>lua require('package-info').delete()<cr>",
			{ silent = true, noremap = true }
		)
		vim.api.nvim_set_keymap(
			"n",
			"<leader>ns",
			"<cmd>lua require('package-info').show()<cr>",
			{ silent = true, noremap = true }
		)
		vim.api.nvim_set_keymap(
			"n",
			"<leader>ni",
			"<cmd>lua require('package-info').install()<cr>",
			{ silent = true, noremap = true }
		)
	end,
}
