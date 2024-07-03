return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"jmederosalvarado/roslyn.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/nvim-cmp",
		"b0o/SchemaStore.nvim",
	},
	config = function()
		-- experiment with roslyn instead of omnisharp
		local use_roslyn = true

		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local on_attach = require("langeoys.utils.lsp").on_attach
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("langeoys-lsp-attach", { clear = true }),
			callback = function(event)
				on_attach(event)
			end,
		})

		local capabilities = cmp_nvim_lsp.default_capabilities()
		local handlers = {
			function(server_name) -- default handler (optional)
				require("lspconfig")[server_name].setup({
					capabilities = capabilities,
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
							misc = {
								-- parameters = { "--loglevel=trace" },
							},
							-- hover = { expandAlias = false },
							type = {
								castNumberToInteger = true,
							},
							diagnostics = {
								disable = { "incomplete-signature-doc", "trailing-space" },
								-- enable = false,
								groupSeverity = {
									strong = "Warning",
									strict = "Warning",
								},
								groupFileStatus = {
									["ambiguity"] = "Opened",
									["await"] = "Opened",
									["codestyle"] = "None",
									["duplicate"] = "Opened",
									["global"] = "Opened",
									["luadoc"] = "Opened",
									["redefined"] = "Opened",
									["strict"] = "Opened",
									["strong"] = "Opened",
									["type-check"] = "Opened",
									["unbalanced"] = "Opened",
									["unused"] = "Opened",
								},
								unusedLocalExclude = { "_*" },
							},
						},
					},
				})
			end,
			["kotlin_language_server"] = function()
				require("lspconfig").kotlin_language_server.setup({
					capabilities = capabilities,
					settings = { kotlin = { compiler = { jvm = { target = "20" } } } },
				})
			end,
			-- no-op, configured in seperate plugins
			["jdtls"] = function() end,
			["yamlls"] = function()
				require("lspconfig").yamlls.setup({
					capabilities = capabilities,
					settings = {
						["yamlls"] = {
							schemaStore = {
								enable = false,
								url = "",
							},
							schemas = require("schemastore").yaml.schemas(),
						},
					},
				})
			end,
			["rust_analyzer"] = function()
				require("lspconfig").rust_analyzer.setup({
					capabilities = capabilities,
					settings = {
						["rust-analyzer"] = {
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								buildScripts = {
									enable = true,
								},
							},
							-- Add clippy lints for Rust.
							checkOnSave = {
								allFeatures = true,
								command = "clippy",
								extraArgs = { "--no-deps" },
							},
							procMacro = {
								enable = true,
								ignored = {
									["async-trait"] = { "async_trait" },
									["napi-derive"] = { "napi" },
									["async-recursion"] = { "async_recursion" },
								},
							},
						},
					},
				})
			end,
		}

		if use_roslyn then
			require("roslyn").setup({
				roslyn_version = "4.8.0-3.23475.7", -- this is the default
				capabilities = capabilities, -- required
				on_attach = on_attach,
			})
		end

		-- Får rar feil med at lsp feiler etter save, se https://github.com/neovim/neovim/issues/12970
		vim.lsp.util.apply_text_document_edit = function(text_document_edit, index, offset_encoding)
			local text_document = text_document_edit.textDocument
			local bufnr = vim.uri_to_bufnr(text_document.uri)
			if offset_encoding == nil then
				vim.notify_once(
					"apply_text_document_edit must be called with valid offset encoding",
					vim.log.levels.WARN
				)
			end

			vim.lsp.util.apply_text_edits(text_document_edit.edits, bufnr, offset_encoding)
		end

		require("mason").setup()
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

		local config = {
			virtual_text = {
				prefix = "●",
				format = function(diagnostic)
					require("langeoys.utils.lua")
					return Split(diagnostic.message, "\n")[1]
				end,
			},
			update_in_insert = false,
			underline = true,
			severity_sort = true,
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "",
					[vim.diagnostic.severity.WARN] = "",
					[vim.diagnostic.severity.HINT] = "󰌵",
					[vim.diagnostic.severity.INFO] = "",
				},
			},
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
