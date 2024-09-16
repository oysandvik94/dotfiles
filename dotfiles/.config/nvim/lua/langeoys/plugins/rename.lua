return {
	"smjonas/inc-rename.nvim",
	config = function()
		require("inc_rename").setup({})
		vim.cmd(":set inccommand=split")
		vim.keymap.set("n", "<leader>lr", function()
			return ":IncRename " .. vim.fn.expand("<cword>")
		end, { expr = true })
	end,
}
