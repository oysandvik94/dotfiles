return {
  "goolord/alpha-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function(_, dashboard)
    require("alpha").setup(dashboard.opts)
  end,
  opts = function()
    local dashboard = require("alpha.themes.dashboard")
    local header = {
      "       ,                                  ",
      "       \\`-._           __                 ",
      "        \\\\  `-..____,.'  `.               ",
      "         :`.         /    \\`.             ",
      "         :  )       :      : \\            ",
      "          ;'        '   ;  |  :           ",
      "          )..      .. .:.`.;  :           ",
      "         /::...  .:::...   ` ;            ",
      "         ; _ '    __        /:\\           ",
      "         `:o>   /\\o_>      ;:. `.         ",
      "        `-`.__ ;   __..--- /:.   \\        ",
      "        === \\_/   ;=====_.':.     ;       ",
      "         ,/'`--'...`--....        ;       ",
      "              ;                    ;      ",
      "            .'                      ;     ",
      "          .'                        ;     ",
      "        .'     ..     ,      .       ;    ",
      "       :       ::..  /      ;::.     |    ",
      "      /      `.;::.  |       ;:..    ;    ",
      "     :         |:.   :       ;:.    ;     ",
      "     :         ::     ;:..   |.    ;      ",
      "      :       :;      :::....|     |      ",
      "      /\\     ,/ \\      ;:::::;     ;      ",
      "    .:. \\:..|    :     ; '.--|     ;      ",
      "   ::.  :''  `-.,,;     ;'   ;     ;      ",
      ".-'. _.'\\      / `;      \\,__:      \\     ",
      "`---'    `----'   ;      /    \\,.,,,/     ",
      "                   `----`                 ",
    }
    dashboard.section.header.val = header
    dashboard.section.buttons.val = {
      dashboard.button("f", " " .. " Find file", "<cmd>lua require('fzf-lua').files()<CR>"),
      dashboard.button(
        "g",
        " " .. " Find text",
        "<cmd>lua require('fzf-lua').live_grep_glob({rg_opts = \"--column --hidden --line-number --no-heading --color=always --smart-case --max-columns=4096 -e\"})<CR>"
      ),
      dashboard.button("l", "󰒲 " .. " Lazy", ":Lazy<CR>"),
      dashboard.button(
        "s",
        "󰁯 " .. " Restore last session",
        ":lua require('langeoys.utils.session').load_last_session()<CR>"
      ),
      dashboard.button("q", " " .. " Quit", ":qa<CR>"),
    }
    for _, button in ipairs(dashboard.section.buttons.val) do
      button.opts.hl = "AlphaHeader"
      button.opts.hl_shortcut = "AlphaHeader"
    end
    dashboard.section.terminal.width = 70
    dashboard.section.terminal.height = 10
    dashboard.section.terminal.opts.redraw = true
    dashboard.section.terminal.opts.window_config.zindex = 1
    return dashboard
  end,
}
