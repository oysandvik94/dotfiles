return {
	dir = "~/dev/general/curl.nvim/",
	-- "oysandvik94/curl.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("curl").setup({
			storage = "session",
		})
	end,
}
