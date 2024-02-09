local function deprio(kind)
	return function(e1, e2)
		if e1:get_kind() == kind then
			return false
		end
		if e2:get_kind() == kind then
			return true
		end
	end
end

-- Put methods from Object class in java at bottom, so that more specific methods are prioritized
local function downpri_object_methods(entry1, entry2)
	local e1 = entry1.completion_item
	local e2 = entry2.completion_item

	local client = nil
	if entry1.source.source and entry1.source.source.client then
		client = entry1.source.source.client.name
	end

	if client ~= nil and client == "jdtls" then
		if e1.detail and string.match(e1.detail, "Object.") then
			return false
		end
		if e2.detail and string.match(e2.detail, "Object.") then
			return true
		end
	end
end

local function under(entry1, entry2)
	local _, entry1_under = entry1.completion_item.label:find("^_+")
	local _, entry2_under = entry2.completion_item.label:find("^_+")
	entry1_under = entry1_under or 0
	entry2_under = entry2_under or 0
	if entry1_under > entry2_under then
		return false
	elseif entry1_under < entry2_under then
		return true
	end
end

local function tableContains(table, value)
	for i = 1, #table do
		if table[i] == value then
			return true
		end
	end
	return false
end

local parameterizedTypes = {
	2,
	3,
	4,
}
local function formatLspFunctions(entry, vim_item)
	local item = entry:get_completion_item()

	if entry.source.source.client.name ~= "jdtls" then
        -- set max width
        if vim_item.menu then
            vim_item.menu = string.sub(vim_item.menu, 1, 10)
        end
		return vim_item
	end
	if tableContains(parameterizedTypes, item.kind) then
		vim_item.abbr = item.label .. item.labelDetails.detail
		if item.kind ~= 4 then
			vim_item.menu = item.labelDetails.description
		end
	end

	return vim_item
end

return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		{ "hrsh7th/nvim-cmp" }, -- Required
		{ "hrsh7th/cmp-buffer" },
		{ "hrsh7th/cmp-nvim-lsp" }, -- Required
		{ "hrsh7th/cmp-cmdline" },
		{ "rcarriga/cmp-dap" },
		{ "hrsh7th/cmp-path" },
		{ "hrsh7th/cmp-nvim-lua" },
		{ "L3MON4D3/LuaSnip" }, -- Required
		"saadparwaiz1/cmp_luasnip",
		"rafamadriz/friendly-snippets",
		{ "onsails/lspkind.nvim" },
		{ "hrsh7th/cmp-nvim-lsp-signature-help" },
	},
	enabled = true,
	config = function()
		local cmp = require("cmp")
		local lspkind = require("lspkind")

		require("luasnip.loaders.from_vscode").lazy_load()

		local cmp_select_opts = { behavior = cmp.SelectBehavior.Insert }
		--
		-- key mappings for Alt+number to select, have to press enter after to confirm though
		local keys = {
			["<C-K>"] = cmp.mapping.complete(),
			["<C-p>"] = cmp.mapping(function()
				if cmp.visible() then
					cmp.select_prev_item(cmp_select_opts)
				else
					cmp.complete()
				end
			end),
			["<C-n>"] = cmp.mapping(function()
				if cmp.visible() then
					cmp.select_next_item(cmp_select_opts)
				else
					cmp.complete()
				end
			end),
			["<C-d>"] = cmp.mapping.scroll_docs(-4),
			["<C-u>"] = cmp.mapping.scroll_docs(4),
			["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
			["<C-e>"] = cmp.mapping.abort(), -- close completion window
			["<C-y>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert }),
			["<C-h>"] = function() end,
		}

		for i = 1, 10, 1 do
			local key = table.concat({ "<M-", (i < 10 and i or 0), ">" })
			keys[key] = function(fallback)
				if cmp.visible() then
					-- need this to enter the menu
					if cmp.get_selected_entry() == nil then
						cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
					end

					cmp.select_next_item({ count = i - 1, behavior = cmp.SelectBehavior.Insert })
					cmp.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert })
				end

				fallback()
			end
		end

		vim.opt.pumheight = 10
		-- local log = require('plenary.log').new {
		--     plugin = "cmp",
		--     level = "debug"
		-- }
		---@diagnostic disable-next-line: missing-fields
		local types = require("cmp.types")
		cmp.setup({
			---@diagnostic disable-next-line: missing-fields
			completion = {
				completeopt = "menu,menuone,preview,noselect",
			},
			sorting = {
				comparators = {
					-- deprio(types.lsp.CompletionItemKind.Snippet),
					-- cmp.config.compare.recently_used,
					cmp.config.compare.offset,
					cmp.config.compare.score,
					cmp.config.compare.exact,
					under,
					downpri_object_methods,
					cmp.config.compare.kind,
					cmp.config.compare.sort_text,
					cmp.config.compare.length,
					cmp.config.compare.order,
				},
			},
			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body)
				end,
			},
			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},
			view = {
				entries = { name = "custom", selection_order = "near_cursor" },
			},
			sources = {
				{
					name = "nvim_lsp",
					entry_filter = function(entry, ctx)
						local kind = require("cmp.types.lsp").CompletionItemKind[entry:get_kind()]
						if kind == "Snippet" and ctx.prev_context.filetype == "java" then
							if entry:get_completion_item().label == "class" then
								return true
							end

							return false
						end
						return true
					end,
				},
				{ name = "nvim_lua" },
				{ name = "luasnip" },
				{ name = "buffer", keyword_length = 5 },
				{ name = "path" },
				-- { name = "copilot" }
			},
			mapping = keys,
			---@diagnostic disable-next-line: missing-fields
			formatting = {
				format = lspkind.cmp_format({
					mode = "symbol_text",
					-- maxwidth = 10,
					-- ellipsis_char = "...",
					symbol_map = { Copilot = "" },
					before = function(entry, vim_item)
						local source = entry.source.name
						if source == "nvim_lsp" then
							vim_item = formatLspFunctions(entry, vim_item)
							return vim_item
						end

						return vim_item
					end,
				}),
			},
		})
		require("lspkind").init({
			symbol_map = {
				Copilot = "",
			},
		})

		vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })

		-- Setup for cmdline
		-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
		cmp.setup.cmdline({ "/", "?" }, {
			mapping = cmp.mapping.preset.cmdline(),
			sources = {
				{ name = "buffer" },
			},
		})

		-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({
				{ name = "path" },
			}, {
				{ name = "cmdline" },
			}),
		})

		-- If you want insert `(` after select function or method item
		local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

		require("cmp").setup({
			enabled = function()
				return vim.api.nvim_get_option_value("buftype", { buf = 0 }) ~= "prompt"
					or require("cmp_dap").is_dap_buffer()
			end,
		})

		require("cmp").setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
			sources = {
				{ name = "dap" },
			},
		})

		-- set highlight LspSignatureActiveParameter
		-- vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", { fg = "#6CC644" })
		vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", { ctermbg = 0, fg = "#31748F", bg = "#EBBCBA" })

		vim.keymap.set({ "n" }, "<Leader>k", function()
			vim.lsp.buf.signature_help()
		end, { silent = true, noremap = true, desc = "toggle signature" })
		vim.keymap.set({ "i" }, "<A-k>", function()
			vim.lsp.buf.signature_help()
		end, { silent = true, noremap = true, desc = "toggle signature" })
	end,
}
