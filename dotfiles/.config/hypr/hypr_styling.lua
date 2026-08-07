-- Theme / visuals.
hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 6,
    border_size = 2,
    resize_on_border = true,
    col = {
      active_border = 0xff7894ab,
      inactive_border = 0x66313244,
      nogroup_border = 0xff89dceb,
      nogroup_border_active = 0xfff9e2af,
    },
  },

  decoration = {
    rounding = 10,
    active_opacity = 1.0,
    inactive_opacity = 0.9,
    dim_inactive = false,
    dim_strength = 0.2,
    blur = {
      enabled = true,
      size = 5,
      passes = 3,
      vibrancy = 0.1696,
    },
    shadow = {
      enabled = true,
      range = 8,
      render_power = 3,
      color = 0x407894ab,
      color_inactive = 0x10000000,
    },
  },

  animations = {
    enabled = true,
  },
})

hl.curve("overshot", {
  type = "bezier",
  points = { { 0.05, 0.9 }, { 0.1, 1.1 } },
})

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "overshot" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "default", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default", style = "slidefade 60%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6, bezier = "default", style = "slidefadevert 20%" })

-- Override for special workspace animation used by scratchpads.
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "default", style = "slidevert" })

