return {
	"L3MON4D3/LuaSnip",
	config = function()
		local ls = require("luasnip")

		vim.keymap.set("n", "<leader><leader>s", function()
			require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/lua/langeoys/snippets" })
		end, { silent = true })

		require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/lua/langeoys/snippets" })

		vim.snippet.expand = ls.lsp_expand

		vim.snippet.active = function(filter)
			filter = filter or {}
			filter.direction = filter.direction or 1

			if filter.direction == 1 then
				return ls.expand_or_jumpable()
			else
				return ls.jumpable(filter.direction)
			end
		end

		vim.snippet.jump = function(direction)
			if direction == 1 then
				if ls.expandable() then
					return ls.expand_or_jump()
				else
					return ls.jumpable(1) and ls.jump(1)
				end
			else
				return ls.jumpable(-1) and ls.jump(-1)
			end
		end

		vim.snippet.stop = ls.unlink_current

		-- ================================================
		--      My Configuration
		-- ================================================
		ls.config.set_config({
			history = true,
			updateevents = "TextChanged,TextChangedI",
			override_builtin = true,
		})

		vim.keymap.set({ "n", "i", "s" }, "<c-f>", function()
			return vim.snippet.active({ direction = 1 }) and vim.snippet.jump(1)
		end, { silent = true })

		vim.keymap.set({ "i", "s" }, "<c-b>", function()
			return vim.snippet.active({ direction = -1 }) and vim.snippet.jump(-1)
		end, { silent = true })
	end,
}
