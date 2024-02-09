return {
	"ThePrimeagen/git-worktree.nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		require("git-worktree").setup({})
		require("telescope").load_extension("git_worktree")

		local Worktree = require("git-worktree")

		-- op = Operations.Switch, Operations.Create, Operations.Delete
		-- metadata = table of useful values (structure dependent on op)
		--      Switch
		--          path = path you switched to
		--          prev_path = previous worktree path
		--      Create
		--          path = path where worktree created
		--          branch = branch name
		--          upstream = upstream remote name
		--      Delete
		--          path = path where worktree deleted

		Worktree.on_tree_change(function(op, metadata)
			if op == Worktree.Operations.Switch then
				local absolute_path = vim.fn.expand(metadata.path)
				local absolute_prev_path = vim.fn.expand(metadata.prev_path)

				local marks_util = require("langeoys.utils.marks")

				marks_util.restore_wormtree_marks(absolute_path, absolute_prev_path)

				require("session_manager").load_current_dir_session()

                require("langeoys.utils.session").store_last_worktree_branch(absolute_path)
            elseif op == Worktree.Operations.Create then
                require("langeoys.utils.session").store_last_worktree_branch(vim.loop.cwd() .. "/" .. metadata.path)
			end
		end)
	end,
	keys = {
		{ "<leader>gw", "<cmd>lua require('telescope').extensions.git_worktree.git_worktrees()<CR>" },
		{ "<leader>gW", "<cmd>lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>" },
	},
}
