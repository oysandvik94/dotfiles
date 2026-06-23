-- Keybindings.
local fileManager = "dolphin"
local menu = "rofi -show drun -config ~/.config/rofi/configs/config.rasi -width 420"
local powermenu = "~/.config/rofi/scripts/powermenu"

local mainMod = "SUPER"

hl.bind(mainMod .. " + return", hl.dsp.exec_cmd("sh -c 'GTK_IM_MODULE=simple ghostty'"))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(powermenu))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))

hl.bind(mainMod .. " + z", hl.dsp.layout("rollnext"))
hl.bind(mainMod .. " + z", hl.dsp.layout("focusmaster master"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[grim -g "$(slurp -d)" - | wl-copy]]))

-- Media / io
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("playerctl next"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("playerctl previous"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brightnessctl set 10%+"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("brightnessctl set 10%-"))

hl.bind(
  mainMod .. " + CTRL + V",
  hl.dsp.exec_cmd(
    [[cliphist list | rofi -dmenu -window-title "Clipboard history" -config ~/.config/rofi/configs/config.rasi -width 420 | cliphist decode | wl-copy]]
  )
)

hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("~/dotfiles/dotfiles/scripts/theme.sh"))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd("1password --ozone-platform-hint=wayland --quick-access"))

-- Dropdown terminal (special workspace)
hl.window_rule({
  name = "apply-dropdown-terminal",
  match = { class = "com.example.dropdown" },
  float = true,
  center = true,
  size = "(monitor_w*0.6) (monitor_h*0.6)",
  persistent_size = true,
})

-- AI popup (special workspace)
hl.window_rule({
  name = "apply-ai-popup",
  match = { class = "com.example.ai-dropdown" },
  float = true,
  center = true,
  size = "(monitor_w*0.6) (monitor_h*0.6)",
  persistent_size = true,
})

-- Special workspace toggles
hl.bind(mainMod .. " + T", hl.dsp.workspace.toggle_special("dropdown"))
hl.bind(mainMod .. " + A", hl.dsp.workspace.toggle_special("ai"))
