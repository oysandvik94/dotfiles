return {
	"saghen/blink.cmp",
	lazy = false, -- lazy loading handled internally
	-- optional: provides snippets for the snippet source
	dependencies = "rafamadriz/friendly-snippets",
	enabled = true,
	build = "cargo build --release",
	opts = {
		-- nerd_font_variant = "normal",

		-- experimental auto-brackets support
		accept = { auto_brackets = { enabled = true } },

		-- experimental signature help support
		trigger = { signature_help = { enabled = true } },
		-- keymap = {
		-- 	accept = { "<CR>" },
		-- 	show_documentation = "<Tab>",
		-- },
		keymap = {
			["<Tab>"] = { "accept" },
			["<Down>"] = { "select_next", "show" },
			["<Up>"] = { "select_prev", "show" },
		},
		windows = {
			documentation = {
				min_width = 10,
				max_width = 60,
				max_height = 20,
				border = "padded",
				winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None",
				-- which directions to show the documentation window,
				-- for each of the possible autocomplete window directions,
				-- falling back to the next direction when there's not enough space
				direction_priority = {
					autocomplete_north = { "e", "w", "n", "s" },
					autocomplete_south = { "e", "w", "s", "n" },
				},
				auto_show = true,
				auto_show_delay_ms = 200,
				update_delay_ms = 50,
			},
		},
	},
}
