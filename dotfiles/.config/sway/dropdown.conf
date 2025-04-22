# Set your preferred terminal emulator
set $title dropdown
set $term kitty --title $title  

# Execute your preferred terminal emulator in scratchpad  
exec $term  

# Move the terminal to scratchpad and set its size and position
for_window [title="$title"] move container to scratchpad
for_window [title="$title"] floating enable, resize set 800 600, move position center

# Bind your preferred shortcut to show / hide the terminal  
bindsym $mod+t scratchpad show  

