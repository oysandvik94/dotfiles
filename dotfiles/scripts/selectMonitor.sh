#!/usr/bin/env sh

ALL_MONITORS=$(hyprctl monitors -j | jq -r '.[] | .name')
SELECTED_MONITOR=$(echo -e "$ALL_MONITORS" | fzf)

echo $SELECTED_MONITOR

for monitor in $ALL_MONITORS; do
    if [ "$monitor" != "$SELECTED_MONITOR" ]; then
        echo "Disabling $monitor"
        hyprctl keyword monitor "$monitor,disable"
    fi
done
