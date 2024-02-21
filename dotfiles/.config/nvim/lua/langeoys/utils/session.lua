local M = {}

M.WORKTREE_STATE = "last_worktre"

M.store_last_worktree_branch = function(target_cwd)
	local last_state = {}

	-- ugly hack, because worktree plugin does not provide the actual cwd before switching worktree
	local removedSlug = target_cwd:match("(.-)/[^/]*$")

    if removedSlug == nil then
        -- when worktree is created, switch is called with malformed paths
        return
    end

	last_state[removedSlug] = target_cwd

	require("langeoys.utils.state").save_state(M.WORKTREE_STATE, last_state)
end

M.load_last_session = function()
	-- local worktree_state = require("langeoys.utils.state").get_state(M.WORKTREE_STATE)
	-- local last_work_tree_branch = worktree_state and worktree_state[vim.loop.cwd()]
	--
 --    if last_work_tree_branch then
 --        require("git-worktree").switch_worktree(last_work_tree_branch)
 --        return
 --    end

	require("session_manager").load_current_dir_session()
end

return M
