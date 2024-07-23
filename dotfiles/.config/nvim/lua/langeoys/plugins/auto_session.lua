return {
	"rmagatti/auto-session",
	enabled = true,
	config = function()
		require("auto-session").setup({
			bypass_session_save_file_types = { "netrw", "alpha", "curl", "oil" },
			no_restore_cmds = {
				function()
					vim.cmd("Alpha")
				end,
			},
		})
		vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
	end,
}
