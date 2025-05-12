return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "jmederosalvarado/roslyn.nvim",
    "williamboman/mason-lspconfig.nvim",
    "b0o/SchemaStore.nvim",
    -- "nvim-java/nvim-java",
  },
  config = function()
    -- require("java").setup()

    -- experiment with roslyn instead of omnisharp
    local use_roslyn = true

    local on_attach = require("langeoys.utils.lsp").on_attach
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("langeoys-lsp-attach", { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id) -- Get the client using its ID
        local bufnr = event.buf                                       -- The buffer number
        on_attach(client, bufnr)                                      -- Call your custom on_attach with these arguments
      end,
    })

    local java_rootdir = function()
      return vim.fs.dirname(vim.fs.find({ "gradlew", ".git", "mvnw", "pom.xml" }, { path = vim.fn.getcwd() })[1])
    end

    vim.lsp.config("lua_ls", {
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
    vim.lsp.config("yamlls", {
      settings = {
        ["yamlls"] = {
          schemaStore = {
            enable = false,
            url = "",
          },
          schemas = require("schemastore").yaml.schemas(),
        },
      }
    })
    vim.lsp.config("rust_analyzer", {
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

    require("mason").setup({
      registries = {
        "github:mason-org/mason-registry",
      },
    })
    local mason_lspconfig = require("mason-lspconfig")
    mason_lspconfig.setup({
      ensure_installed = {
        "eslint",
        "lua_ls",
        "bashls",
        "kotlin_language_server",
        "pyright",
        "clangd",
      },

      automatic_installation = true,
      automatic_enable = {
        exclude = {
          "jdtls"
        }
      }
    })
    -- mason_lspconfig.setup_handlers(handlers)

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
