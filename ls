# See https://wiki.hyprland.org/Configuring/Monitors/
monitor=,highres,auto,1,bitdepth,10


# See https://wiki.hyprland.org/Configuring/Keywords/ for more


# Source a file (multi-file configs)
source = ~/.config/hypr/autostart.conf
source = ~/.config/hypr/styling.conf

bin
dotfiles
philemon

# Set programs that you use
$terminal = kitty
$fileManager = dolphin
$menu = rofi -show drun -config ~/.config/rofi/configs/config.rasi -width 420
$powermenu = ~/.config/rofi/scripts/powermenu 
$screenshot = maim -o --select | xclip -selection clipboard -t image/png

# Some default env vars.
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct # change to qt6ct if you have that

# For all categories, see https://wiki.hyprland.org/Configuring/Variables/
input {
    kb_layout = no
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1

    touchpad {
        disable_while_typing = true
        natural_scroll = true
    }

    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(cba6f7ff) rgba(89b4faff) rgba(94e2d5ff) 10deg
    col.inactive_border = 0xff313244
    col.nogroup_border = 0xff89dceb
    col.nogroup_border_active = 0xfff9e2af
    cursor_inactive_timeout = 5
    resize_on_border = true
}

decoration {
  # █▀█ █▀█ █░█ █▄░█ █▀▄   █▀▀ █▀█ █▀█ █▄░█ █▀▀ █▀█
  # █▀▄ █▄█ █▄█ █░▀█ █▄▀   █▄▄ █▄█ █▀▄ █░▀█ ██▄ █▀▄
  rounding = 18

  # █▀█ █▀█ ▄▀█ █▀▀ █ ▀█▀ █▄█
  # █▄█ █▀▀ █▀█ █▄▄ █ ░█░ ░█░
  active_opacity = 1.0
  inactive_opacity = 0.95

  # █▄▄ █░░ █░█ █▀█
  # █▄█ █▄▄ █▄█ █▀▄
  blur:enabled = true
  blur:size = 2
  blur:passes = 2


  # █▀ █░█ ▄▀█ █▀▄ █▀█ █░█░█
  # ▄█ █▀█ █▀█ █▄▀ █▄█ ▀▄▀▄▀
  drop_shadow = true
  shadow_ignore_window = true
  shadow_offset = 2 2
  shadow_range = 8
  shadow_render_power = 10
  col.shadow = rgba(00000055)
  blurls = gtk-layer-shell
  blurls = lockscreen
}


animations {
    enabled = true
    # bezier = overshot, 0.05, 0.9, 0.1, 1.1
    bezier = overshot, 0.13, 0.99, 0.29, 1.1
    animation = windows, 1, 4, overshot, slide
    animation = border, 1, 10, default
    animation = fade, 1, 10, default
    animation = workspaces, 1, 6, overshot, slidevert
}


dwindle {
    # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
    pseudotile = yes # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
    preserve_split = yes # you probably want this
}

master {
    # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
    new_is_master = true
}

gestures {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    workspace_swipe = off
}

misc {
    disable_hyprland_logo = true

    focus_on_activate = true

    enable_swallow = true
    swallow_regex = ^(kitty)$
}

# Example per-device config
# See https://wiki.hyprland.org/Configuring/Keywords/#executing for more
device:epic-mouse-v1 {
    sensitivity = -0.5
}

# Example windowrule v1
# windowrule = float, ^(kitty)$
# Example windowrule v2
# windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
# See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
windowrulev2 = nomaximizerequest, class:.* # You'll probably like this.


# See https://wiki.hyprland.org/Configuring/Keywords/ for more
$mainMod = SUPER

# Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
bind = $mainMod, return, exec, $terminal
bind = $mainMod, C, killactive, 
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, D, exec, $menu
bind = $mainMod, Q, exec, $powermenu
bind = $mainMod SHIFT, J, togglesplit, # dwindle

# Move focus with mainMod + arrow keys
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d
bind = $mainMod, h, movefocus, l
bind = $mainMod, j, movefocus, d
bind = $mainMod, k, movefocus, u
bind = $mainMod, l, movefocus, r


# Switch workspaces with mainMod + [0-9]
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Example special workspace (scratchpad)
bind = $mainMod, S, togglespecialworkspace, magic

# Scroll through existing workspaces with mainMod + scroll
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

bind = $mainMod SHIFT, S, exec, grim -g "$(slurp -d)" - | wl-copy
