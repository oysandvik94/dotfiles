---@module 'snacks'
local function folders()
  local cmd = string.format([[fd --color always --hidden --exclude .git --type directory --max-depth 8]])
  local has_exa = vim.fn.executable("eza") == 1

  local output = vim.fn.systemlist(cmd)
  if not output or #output == 0 then
    vim.notify("No folders found", vim.log.levels.WARN)
    return
  end

  vim.ui.select(output, {
    prompt = "󰥨  Folders❯ ",
    format_item = function(item)
      return item
    end
  }, function(choice)
    if not choice then return end
    require("oil").open(choice)
  end)
end
return {
  "folke/snacks.nvim",
  dependencies = {
    "folke/which-key.nvim",
  },
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    statuscolumn = {
      enabled = true,
      folds = {
        open = true,   -- show open fold icons
        git_hl = true, -- use Git Signs hl for fold icons
      },
    },
    words = { enabled = true },
    scroll = { enabled = true },
    picker = {
      enabled = true,
      formatters = {
        file = {
          filename_first = true, -- display filename before the file path
        },
      },
    },
    styles = {
      notification = {
        wo = { wrap = true }, -- Wrap notifications
      },
    },
    toggle = {
      which_key = true,
    },
  },
  keys = {
    { "<leader>/",  function() Snacks.picker.smart({ hidden = true }) end,     desc = "picker files" },
    { "<leader>fp", function() Snacks.picker() end,                            desc = "picker files" },
    { "<leader>f:", function() Snacks.picker.command_history() end,            desc = "Command history" },
    { "<leader>fc", function() Snacks.picker.commands() end,                   desc = "Command history" },
    { "<leader>fr", function() Snacks.picker.recent() end,                     desc = "Recent" },
    { "<leader>fg", function() Snacks.picker.grep({ hidden = true }) end,      desc = "Grep" },
    { "<leader>fm", function() folders() end,                                  desc = "Search folders" },
    { "<leader>fw", function() Snacks.picker.grep_word({ hidden = true }) end, desc = "Visual selection or word", mode = { "n", "x" } },
    { "<leader>fh", function() Snacks.picker.help() end,                       desc = "Help Pages" },
    { "<leader>fl", function() Snacks.picker.resume() end,                     desc = "Help Pages" },
    { "<leader>zm", function() Snacks.zen() end,                               desc = "Toggle Zen Mode" },
    {
      "<leader>uH",
      function()
        Snacks.notifier.show_history()
      end,
      desc = "Dismiss All Notifications",
    },
    {
      "<leader>un",
      function()
        Snacks.notifier.hide()
      end,
      desc = "Dismiss All Notifications",
    },
    {
      "<leader>bo",
      function()
        Snacks.bufdelete.other(opts)
      end,
      desc = "Delete all buffers except the current one",
    },
    {
      "<leader>bd",
      function()
        Snacks.bufdelete()
      end,
      desc = "Delete Buffer",
    },
    {
      "<leader>gb",
      function()
        Snacks.git.blame_line()
      end,
      desc = "Git Blame Line",
    },
    {
      "<leader>gB",
      function()
        Snacks.gitbrowse()
      end,
      desc = "Git Browse",
    },
    {
      "]]",
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = "Next Reference",
    },
    {
      "[[",
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = "Prev Reference",
    },
    {
      "<leader>N",
      desc = "Neovim News",
      function()
        Snacks.win({
          file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = "yes",
            statuscolumn = " ",
            conceallevel = 3,
          },
        })
      end,
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.inlay_hints():map("<leader>uh")

        local format_toggle = function(buf)
          return Snacks.toggle({
            name = "Auto Format (" .. (buf and "Buffer" or "Global") .. ")",
            get = function()
              return vim.g.AUTOFORMAT == nil or vim.g.AUTOFORMAT
            end,
            set = function(state)
              vim.g.AUTOFORMAT = state
            end,
          })
        end
        format_toggle():map("<leader>uf")
      end,
    })
  end,
}
