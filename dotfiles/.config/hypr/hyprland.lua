-- Hyprland main config (Lua). Split into modules on purpose:
-- each require() is isolated so one error does not prevent others loading.
require("hypr_env")
require("hypr_base")
require("hypr_styling")
require("hypr_layout")
require("hypr_keybindings")
pcall(require, "hypr_local")
require("hypr_autostart")


-- hyprmon: managed monitor profile include
require("hyprmon")
