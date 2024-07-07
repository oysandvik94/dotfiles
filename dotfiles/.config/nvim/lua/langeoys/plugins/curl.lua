return {
	dir = "~/dev/general/curl.nvim/",
	-- "oysandvik94/curl.nvim",
	-- branch = "filetype",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("curl").setup()
	end,
}
