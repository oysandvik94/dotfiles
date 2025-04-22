return {
  "olimorris/codecompanion.nvim",
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
    adapters = {
      anthropic = function()
        return require("codecompanion.adapters").extend("anthropic", {
          env = {
            api_key = "MY_OTHER_ANTHROPIC_KEY",
          },
        })
      end,
    },
  },
  -- init = {
  --   require("langeoys.utils.fidget-spinner"):init()
  -- },
  init = function()
    require("langeoys.utils.fidget-spinner"):init()
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "j-hui/fidget.nvim"
  },
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
