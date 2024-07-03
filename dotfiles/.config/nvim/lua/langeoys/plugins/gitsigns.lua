return {
	"lewis6991/gitsigns.nvim",
	config = function()
		require("gitsigns").setup({
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end
				-- Navigation
				map("n", "]c", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "zz<Ignore>"
				end, { expr = true, desc = "Go to next hunk" })

				map("n", "[c", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "zz<Ignore>"
				end, { expr = true, desc = "Go to previous hunk" })

				-- Actions
				map("n", "<leader>cs", gs.stage_hunk, { desc = "Stage hunk" })
				map("n", "<leader>cr", gs.reset_hunk, { desc = "Reset hunk" })
				map("v", "<leader>cs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "Stage hunk" })
				map("v", "<leader>cr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "Reset hunk" })
				map("n", "<leader>cu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
				map("n", "<leader>cp", gs.preview_hunk_inline, { desc = "Preview hunk" })
				map("n", "<leader>cb", function()
					gs.blame_line({ full = true })
				end, { desc = "Git blame for this line" })
				map("n", "<leader>cd", gs.diffthis, { desc = "Diff this line" })
				map("n", "<leader>ctd", gs.toggle_deleted, { desc = "Toggle deleted lines" })

				-- Text object
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
			end,
		})
	end,
}
