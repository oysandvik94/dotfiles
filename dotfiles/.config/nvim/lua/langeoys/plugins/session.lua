return {
	"Shatur/neovim-session-manager",
	config = function()
		local Path = require("plenary.path")
		local config = require("session_manager.config")

		require("session_manager").setup({
			sessions_dir = Path:new(vim.fn.stdpath("data"), "sessions"), -- The directory where the session files will be saved.
			autoload_mode = config.AutoloadMode.Disabled, -- Define what to do when Neovim is started without arguments. Possible values: Disabled, CurrentDir, LastSession
			autosave_ignore_buftypes = {}, -- All buffers of these bufer types will be closed before the session is saved.
		})

		vim.keymap.set("n", "<leader>wr", "<cmd>SessionManager load_last_session<CR>", { desc = "Restore session for cwd" }) -- restore last workspace session for current directory
		-- Auto save session
		vim.api.nvim_create_autocmd({ "BufWritePre" }, {
			callback = function()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					-- Don't save while there's any 'nofile' buffer open.
					if vim.api.nvim_get_option_value("buftype", { buf = buf }) == "nofile" then
						return
					end
				end
				require('session_manager').save_current_session()
			end,
		})
	end,
}
