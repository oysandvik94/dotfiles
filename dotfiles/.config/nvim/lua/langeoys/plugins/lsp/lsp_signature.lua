return {
	"ray-x/lsp_signature.nvim",
	config = function()
		require("lsp_signature").setup({
			bind = true, -- This is mandatory, otherwise border config won't get registered.
			handler_opts = {
				border = "single",
			},
			hint_enable = true,
			hint_inline = function()
				return false
			end,
			hint_prefix = "",
			select_signature_key = "A-s",
		})
		vim.keymap.set({ "i" }, "<A-k>", function()
			require("lsp_signature").toggle_float_win()
		end, { silent = true, noremap = true, desc = "toggle signature" })
	end,
	ft = { "typescript", "javascript", "lua", "c", "cpp", "go", "python", "java", "rust" },
}
