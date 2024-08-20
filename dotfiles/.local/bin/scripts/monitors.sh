#!/bin/bash

PRIMARY_MONITOR="eDP-1"
PRIMARY_WIDTH="1920"
PRIMARY_HEIGHT="1080"
SECONDARY_MONITOR=$(
    xrandr | awk '/ connected/ {print $1}' | grep -v "${PRIMARY_MONITOR}" |
        fzf --prompt="Please select a display source: "
)
SECONDARY_WIDTH=$(xrandr | awk "/${SECONDARY_MONITOR}/ {print \$3}" | cut -d 'x' -f 1)
SECONDARY_HEIGHT=$(xrandr | awk "/${SECONDARY_MONITOR}/ {print \$3}" | cut -d 'x' -f 2)
SCALING_FACTOR="1.5"

if [ -n "${SECONDARY_MONITOR}" ]; then
    LAYOUT_OPTIONS="Mirror\nSecondary\nLeft\nRight\nTop\nBottom"
else
    echo "No secondary monitor selected!"
    exit 1
fi

ANSWER=$(echo -e "${LAYOUT_OPTIONS}" | fzf --prompt="How do you want to project? " |
    tr '[:upper:]' '[:lower:]')
[ -z "${ANSWER}" ] && {
    echo "No option selected!"
    exit 1
}

case ${ANSWER} in
mirror)
    # hyprctl keyword monitor ${PRIMARY_MONITOR},preferred,auto,1,bitdepth,10
    hyprctl keyword monitor "${PRIMARY_MONITOR}",preferred,auto,1,mirror,"${SECONDARY_MONITOR}"
    ;;
secondary)
    hyprctl keyword monitor ${PRIMARY_MONITOR},disable
    hyprctl keyword monitor "${SECONDARY_MONITOR}",preferred,auto,${SCALING_FACTOR}
    ;;
left)
    hyprctl keyword monitor "${SECONDARY_MONITOR}",preferred,0x0,${SCALING_FACTOR}
    hyprctl keyword monitor ${PRIMARY_MONITOR},preferred,"${SECONDARY_WIDTH}"x0,1
    ;;
right)
    hyprctl keyword monitor ${PRIMARY_MONITOR},preferred,0x0,1
    hyprctl keyword monitor "${SECONDARY_MONITOR}",preferred,${PRIMARY_WIDTH}x0,${SCALING_FACTOR}
    ;;
top)
    hyprctl keyword monitor ${PRIMARY_MONITOR},preferred,0x"${SECONDARY_HEIGHT}",1
    hyprctl keyword monitor "${SECONDARY_MONITOR}",preferred,0x0,${SCALING_FACTOR}
    ;;
bottom)
    hyprctl keyword monitor ${PRIMARY_MONITOR},preferred,0x0,1
    hyprctl keyword monitor "${SECONDARY_MONITOR}",preferred,0x${PRIMARY_HEIGHT},${SCALING_FACTOR}
    ;;
*)
    echo "Invalid option selected!"
    exit 1
    ;;
esac
