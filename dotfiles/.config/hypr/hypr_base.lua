-- Core compositor config (input/misc/rules not tied to theme or binds).
-- hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1, mirror = "DP-1" })
hl.config({
  input = {
    kb_layout = "no",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",

    follow_mouse = 1,

    touchpad = {
      disable_while_typing = true,
      natural_scroll = true,
    },

    sensitivity = 0,
  },

  misc = {
    disable_hyprland_logo = true,
    focus_on_activate = true,

    enable_swallow = true,
    swallow_regex = "^(ghostty)$",
  },
})

-- Screen sharing fixes for xwayland-video-bridge.
hl.window_rule({
  name = "xwayland-video-bridge-fixes",
  match = {
    class = "xwaylandvideobridge",
  },

  no_initial_focus = true,
  no_focus = true,
  no_anim = true,
  no_blur = true,
  max_size = { 1, 1 },
  opacity = 0.0,
})

-- Tempfix for Hyprland + Edge.
hl.window_rule({
  name = "tempfix-edge-empty-xwayland",
  match = {
    class = "^()$",
    title = "^()$",
    initial_class = "^()$",
    initial_title = "^()$",
  },

  no_initial_focus = true,
  float = true,
  move = "cursor_x cursor_y",
})
