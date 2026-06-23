-- Autostart.
hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("nm-applet --indicator")

  hl.exec_cmd("brightnessctl set 100%")
  hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
  hl.exec_cmd("swaybg -m fill -i ~/wallpapers/ting.png")

  hl.dispatch(hl.dsp.exec_cmd("slack", { workspace = "1 silent" }))
  hl.dispatch(hl.dsp.exec_cmd("GTK_IM_MODULE=simple ghostty", { workspace = "2 silent" }))

  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- Previously `exec = kanshi` (runs on config reload too). Starting it once avoids duplicates.
  hl.exec_cmd("kanshi")

  -- Previously duplicated in hyprlang config; keep one explicit import set.
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

  -- Scratchpads
  hl.dispatch(
    hl.dsp.exec_cmd("GTK_IM_MODULE=simple ghostty --class=com.example.dropdown",
      { workspace = "special:dropdown silent" })
  )
  hl.dispatch(
    hl.dsp.exec_cmd(
      "GTK_IM_MODULE=simple ghostty --class=com.example.ai-dropdown -e codex --yolo",
      { workspace = "special:ai silent" }
    )
  )
end)
