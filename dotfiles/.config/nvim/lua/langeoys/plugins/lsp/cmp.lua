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

-- downprioritze underscored items
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

	if entry.source.source.client.name == "jdtls" then
		if tableContains(parameterizedTypes, item.kind) then
			if vim_item.kind == "Constructor" then
				-- local new_constr_name = vim_item.word .. vim_item.menu
				-- vim_item.abbr = new_constr_name

				local type = item.detail and vim.split(item.detail, vim_item.word)[1] or ""
				vim_item.menu = type
			else
				local new_function_name = item.label .. item.labelDetails.detail
				if string.len(new_function_name) < 40 then
					new_function_name = string.sub(new_function_name, 1, 40)
					vim_item.abbr = new_function_name
				end

				local return_value = item.labelDetails.description
				vim_item.menu = return_value
			end
		end
	else
		vim_item.menu = ""
	end

	return vim_item
end

return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		{ "hrsh7th/cmp-buffer" },
		{ "ryo33/nvim-cmp-rust" },
		{ "hrsh7th/cmp-nvim-lsp" }, -- Required
		{ "hrsh7th/cmp-cmdline" },
		{ "rcarriga/cmp-dap" },
		{ "hrsh7th/cmp-path" },
		{ "hrsh7th/cmp-nvim-lua" },
		{ "L3MON4D3/LuaSnip" }, -- Required
		"saadparwaiz1/cmp_luasnip",
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
		local prev_func = function()
			if cmp.visible() then
				cmp.select_prev_item(cmp_select_opts)
			else
				cmp.complete()
			end
		end
		local next_func = function()
			if cmp.visible() then
				cmp.select_next_item(cmp_select_opts)
			else
				cmp.complete()
			end
		end
		local keys = {
			["<C-K>"] = cmp.mapping.complete(),
			["<C-p>"] = cmp.mapping(prev_func),
			["<Up>"] = cmp.mapping(prev_func),
			["<C-n>"] = cmp.mapping(next_func),
			["<Down>"] = cmp.mapping(next_func),
			["<C-d>"] = cmp.mapping.scroll_docs(-4),
			["<C-u>"] = cmp.mapping.scroll_docs(4),
			["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
			["<C-e>"] = cmp.mapping.abort(), -- close completion window
			["<C-y>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert }),
			["<Tab>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert }),
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

		-- To toglge doc menu:
		-- https://github.com/hrsh7th/nvim-cmp/pull/1647

		vim.opt.pumheight = 10
		-- require("cmp-rust").deprioritize_postfix,
		-- require("cmp-rust").deprioritize_borrow,
		-- require("cmp-rust").deprioritize_deref,
		-- require("cmp-rust").deprioritize_common_traits,
		local rust_cmp = require("langeoys.utils.rust")
		cmp.setup({
			enabled = function()
				-- disable completion in comments
				local context = require("cmp.config.context")
				-- keep command mode completion enabled when cursor is in a comment
				if vim.api.nvim_get_mode().mode == "c" then
					return true
				else
					return not context.in_treesitter_capture("comment") and not context.in_syntax_group("Comment")
				end
			end,
			---@diagnostic disable-next-line: missing-fields
			completion = {
				completeopt = "menu,menuone,preview,noselect",
			},
			sorting = {
				priority_weight = 2,
				comparators = {
					rust_cmp.deprioritize_postfix,
					rust_cmp.deprioritize_borrow,
					rust_cmp.deprioritize_deref,
					rust_cmp.deprioritize_common_traits,
					cmp.config.compare.offset,
					cmp.config.compare.score,
					cmp.config.compare.exact,
					-- under,
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
			},
			view = {
				entries = { name = "custom" },
			},
			sources = {
				{
					name = "nvim_lsp",
					option = {
						markdown_oxide = {
							keyword_pattern = [[\(\k\| \|\/\|#\)\+]],
						},
					},
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
				{ name = "buffer", keyword_length = 5 },
				{ name = "path" },
			},
			mapping = keys,
			---@diagnostic disable-next-line: missing-fields
			formatting = {
				format = lspkind.cmp_format({
					mode = "symbol_text",
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
		require("lspkind").init({})

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
		-- local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		-- cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

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

		-- If you want insert `(` after select function or method item
		local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", { ctermbg = 0, fg = "#31748F", bg = "#EBBCBA" })

		vim.keymap.set({ "n" }, "<Leader>k", function()
			vim.lsp.buf.signature_help()
		end, { silent = true, noremap = true, desc = "toggle signature" })
		vim.keymap.set({ "i" }, "<A-k>", function()
			vim.lsp.buf.signature_help()
		end, { silent = true, noremap = true, desc = "toggle signature" })
	end,
}
