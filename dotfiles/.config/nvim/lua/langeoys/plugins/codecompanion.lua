return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "j-hui/fidget.nvim",
  },
  config = true,
  opts = {
    chat = {
      adapter = "copilot",
    },
    inline = {
      adapter = "copilot",
    },
    cmd = {
      adapter = "copilot",
    },
    display = {
      diff = {
        enabled = false,
      }
    },
    adapters = {
      copilot = function()
        return require("codecompanion.adapters").extend("copilot", {
          schema = {
            model = {
              default = "claude-3.5-sonnet",
            },
          },
        })
      end
    },
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
