return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "j-hui/fidget.nvim",
    "ravitemer/codecompanion-history.nvim"
  },
  config = true,
  opts = {
    strategies = {
      chat = {
        tools = {
          opts = {
            default_tools = {
              "full_stack_dev"
            }
          }
        }
      }
    },
    chat = {
      adapter = "copilot",
    },
    inline = {
      adapter = "copilot_inline",
    },
    cmd = {
      adapter = "copilot",
    },
    display = {
      diff = {
        enabled = false,
      },
      chat = {
        show_settings = true, -- Show LLM settings at the top of the chat buffer?
      },
    },
    adapters = {
      copilot_inline = function()
        return require("codecompanion.adapters").extend("copilot", {
          schema = {
            model = {
              default = "claude-3.5-sonnet",
            },
          },
        })
      end,
      copilot = function()
        return require("codecompanion.adapters").extend("copilot", {
          schema = {
            model = {
              default = "claude-sonnet-4",
            },
          },
        })
      end
    },
    extensions = {
      history = {
        enabled = true,
        opts = {
          -- Keymap to open history from chat buffer (default: gh)
          keymap = "gh",
          -- Keymap to save the current chat manually (when auto_save is disabled)
          save_chat_keymap = "sc",
          -- Save all chats by default (disable to save only manually using 'sc')
          auto_save = true,
          -- Number of days after which chats are automatically deleted (0 to disable)
          expiration_days = 0,
          -- Picker interface (auto resolved to a valid picker)
          picker = "snacks", --- ("telescope", "snacks", "fzf-lua", or "default")
          -- Customize picker keymaps (optional)
          picker_keymaps = {
            rename = { n = "r", i = "<M-r>" },
            delete = { n = "d", i = "<M-d>" },
            duplicate = { n = "<C-y>", i = "<C-y>" },
          },
          ---Automatically generate titles for new chats
          auto_generate_title = true,
          title_generation_opts = {
            adapter = "copilot",
            model = "gpt-4.1",
            refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
            max_refreshes = 3,
          },
          ---On exiting and entering neovim, loads the last chat on opening chat
          continue_last_chat = false,
          ---When chat is cleared with `gx` delete the chat from history
          delete_on_clearing_chat = false,
          ---Directory path to save the chats
          dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
          ---Enable detailed logging for history extension
          enable_logging = false,
          ---Optional filter function to control which chats are shown when browsing
          chat_filter = nil, -- function(chat_data) return boolean end
        }
      }
    }
  },
  init = function()
    require("langeoys.utils.fidget-spinner"):init()
  end,
  keys = {
    { "<leader>aa", "<cmd>CodeCompanionChat Add<cr>",    desc = "Add to AI chat", mode = { "v" } },
    { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Add to AI chat", mode = { "n" } },
    {
      "<leader>ar",
      function()
        vim.ui.input({ prompt = "Prompt" }, function(prompt)
          vim.cmd("'<,'>CodeCompanion #buffer " .. prompt)
        end)
      end,
      desc = "Inline AI",
      mode = { "n", "v" },
    },
  }
}
