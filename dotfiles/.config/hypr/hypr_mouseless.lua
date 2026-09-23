-- Grid-to-manual mode, or a precise one-shot target-and-click.
hl.bind(
  "SUPER + R",
  hl.dsp.exec_cmd(
    [[wl-kbptr -o modes=tile; hyprctl eval 'hl.config({ ["general.col.active_border"] = 0xffdbbf7f })'; hyprctl dispatch 'hl.dsp.submap("mouse")']]
  )
)
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("wl-kbptr -o modes=tile,click"))

hl.define_submap("mouse", function()
  local leave_mouse = hl.dsp.exec_cmd(
    [[ydotool click 0x80; rm -f "$XDG_RUNTIME_DIR/hypr-mouse-drag"; for state in "$XDG_RUNTIME_DIR"/hypr-mouse-scroll-*; do test -s "$state" && kill "$(cat "$state")" 2>/dev/null; rm -f "$state"; done; hyprctl eval 'hl.config({ ["general.col.active_border"] = 0xff7894ab })'; hyprctl dispatch 'hl.dsp.submap("reset")']]
  )

  -- Temporarily leave the submap so wl-kbptr can read its selection keys.
  hl.bind(
    "a",
    hl.dsp.exec_cmd([[hyprctl dispatch 'hl.dsp.submap("reset")'; wl-kbptr -o modes=tile; hyprctl dispatch 'hl.dsp.submap("mouse")']])
  )

  local function move(key, x, y, modifiers)
    local keys = modifiers and modifiers .. " + " .. key or key
    hl.bind(keys, hl.dsp.exec_cmd("ydotool mousemove -x " .. x .. " -y " .. y), { repeating = true })
  end

  -- M/N/E/I and the number-layer arrows share the same physical keys.
  move("m", -20, 0)
  move("n", 0, 20)
  move("e", 0, -20)
  move("i", 20, 0)
  move("left", -100, 0)
  move("down", 0, 60)
  move("up", 0, -60)
  move("right", 100, 0)
  move("left", -1, 0, "CTRL")
  move("down", 0, 1, "CTRL")
  move("up", 0, -1, "CTRL")
  move("right", 1, 0, "CTRL")

  local function scroll(key, y)
    local state = '"$XDG_RUNTIME_DIR/hypr-mouse-scroll-' .. key .. '"'
    local stop = 'test -s "$state" && kill "$(cat "$state")" 2>/dev/null; rm -f "$state"'
    local start =
      "state=" .. state .. "; " .. stop .. "; (while :; do ydotool mousemove --wheel -x 0 -y " .. y .. "; sleep 0.08; done) & echo $! > \"$state\""

    hl.bind(key, hl.dsp.exec_cmd(start))
    hl.bind(key, hl.dsp.exec_cmd("state=" .. state .. "; " .. stop), { release = true })
  end

  scroll("u", 1)
  scroll("d", -1)

  hl.bind("space", hl.dsp.exec_cmd("ydotool click 0xC0"))
  hl.bind("SHIFT + space", hl.dsp.exec_cmd("ydotool click 0xC1"))

  -- Text selection / drag: v toggles the left button.
  hl.bind(
    "v",
    hl.dsp.exec_cmd(
      [[state="$XDG_RUNTIME_DIR/hypr-mouse-drag"; if test -e "$state"; then ydotool click 0x80; rm -f "$state"; else ydotool click 0x40 && touch "$state"; fi]]
    )
  )

  -- Escape or either Super key safely leaves mouse mode.
  hl.bind("escape", leave_mouse)
  hl.bind("Super_L", leave_mouse, { non_consuming = true })
  hl.bind("Super_R", leave_mouse, { non_consuming = true })
end)
