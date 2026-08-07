return {
  dir = "/home/sandvoys/dev/general/codex-bridge",
  config = function()
    require("codex_bridge").setup()
    require("codex_bridge").setup({
      keymaps = {
        send_selection = "<leader>as",
        send_file = "<leader>af",
        jump = "<leader>aj",
      },
    })
  end,
}
