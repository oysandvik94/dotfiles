#!/bin/bash

# Get current output size
read -r width height < <(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .current_mode | "\(.width) \(.height)"')

# Size as a percentage of screen
term_width=$(awk "BEGIN { print int($width * 0.6) }")
term_height=$(awk "BEGIN { print int($height * 0.4) }")

# Position (centered)
pos_x=$(awk "BEGIN { print int(($width - $term_width) / 2) }")
pos_y=$(awk "BEGIN { print int(($height - $term_height) / 4) }") # top third

# Launch terminal in floating mode, move and resize
swaymsg exec "ghostty --title=dropterm"
sleep 0.1
swaymsg '[title="dropterm"] floating enable, resize set $term_width px $term_height px, move absolute position $pos_x px $pos_y px'
swaymsg '[title="dropterm"] move to scratchpad, scratchpad show'
