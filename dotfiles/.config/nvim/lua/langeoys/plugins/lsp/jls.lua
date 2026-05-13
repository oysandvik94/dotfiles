-- lazy.nvim
return {
  "idelice/nvim-jls",
  enabled = false,
  opts = {
    jls_dir = "/home/sandvoys/bin/jls", -- must contain dist/lang_server_*.sh
    root_markers = { ".git" }
  },
}
