return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"jmederosalvarado/roslyn.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/nvim-cmp",
		"folke/neodev.nvim",
	},
	config = function()
		-- experiment with roslyn instead of omnisharp
		local use_roslyn = true
		-- IMPORTANT: make sure to setup neodev BEFORE lspconfig
		require("neodev").setup({
			-- add any options here, or leave empty to use the default settings
		})

		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local on_attach = require("langeoys.utils.lsp").on_attach

		local capabilities = cmp_nvim_lsp.default_capabilities()
		local handlers = {
			function(server_name) -- default handler (optional)
				require("lspconfig")[server_name].setup({
					capabilities = capabilities,
					on_attach = on_attach,
				})
			end,
			["omnisharp"] = function()
				if not use_roslyn then
					vim.api.nvim_create_autocmd("FileType", {
						pattern = { "cs" },
						desc = "Set dotnet compiler",
						callback = function()
							vim.cmd("compiler dotnet")
						end,
					})

					require("lspconfig").omnisharp.setup({
						capabilities = capabilities,
						on_attach = on_attach,
						settings = {
							solution_first = true,
							enable_editorconfig_support = true,
						},
					})
				end
			end,
			["lua_ls"] = function()
				require("lspconfig").lua_ls.setup({
					capabilities = capabilities,
					on_attach = on_attach,
					settings = {
						Lua = {
							diagnostics = {
								globals = { "vim" },
							},
							workspace = {
								library = {
									[vim.fn.expand("$VIMRUNTIME/lua")] = true,
									[vim.fn.stdpath("config") .. "/lua"] = true,
								},
								maxPreload = 10000, -- Add this if missing or increase it
								preloadFileSize = 10000, -- Add this if missing or increase it
							},
						},
					},
				})
			end,
			["kotlin_language_server"] = function()
				require("lspconfig").kotlin_language_server.setup({
					capabilities = capabilities,
					on_attach = on_attach,
					settings = { kotlin = { compiler = { jvm = { target = "20" } } } },
				})
			end,
			-- no-op, configured in seperate plugins
			["jdtls"] = function() end,
			["rust_analyzer"] = function()
				require("lspconfig").rust_analyzer.setup({
					capabilities = capabilities,
					on_attach = on_attach,
					settings = {
						["rust-analyzer"] = {
							checkOnSave = {
								allFeatures = true,
								overrideCommand = {
									"cargo",
									"clippy",
									"--workspace",
									"--message-format=json",
									"--all-targets",
									"--all-features",
								},
							},
						},
					},
				})
			end,
			["tsserver"] = function() end,
		}

		if use_roslyn then
			require("roslyn").setup({
				roslyn_version = "4.8.0-3.23475.7", -- this is the default
				capabilities = capabilities, -- required
				on_attach = on_attach,
			})
		end

		local mason = require("mason").setup()
		local mason_lspconfig = require("mason-lspconfig")
		mason_lspconfig.setup({
			ensure_installed = {
				"eslint",
				"lua_ls",
				"jdtls",
				"bashls",
				"kotlin_language_server",
				"pyright",
				"clangd",
			},

			automatic_installation = true,
		})
		mason_lspconfig.setup_handlers(handlers)

		-- Configure diagnostics
		local signs = { Error = "", Warn = "", Hint = "󰌵", Info = "" }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
		end
		local config = {
			-- Using lsp_lines.nvim
			virtual_text = true,
			-- show signs
			signs = {
				active = signs,
			},
			update_in_insert = false,
			underline = true,
			severity_sort = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "single",
				source = "always",
				header = "",
				prefix = "",
			},
		}
		vim.diagnostic.config(config)
		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
			border = "single",
		})

		vim.lsp.util.stylize_markdown = function(bufnr, contents, opts)
			contents = vim.lsp.util._normalize_markdown(contents, {
				width = vim.lsp.util._make_floating_popup_size(contents, opts),
			})

			vim.bo[bufnr].filetype = "markdown"
			vim.treesitter.start(bufnr)
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)

			return contents
		end
	end,
}
