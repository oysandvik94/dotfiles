#!/bin/sh

monitorAdded() {
    sleep 1
    connected=$(hyprctl monitors | grep "Monitor" | awk '{print $2}')
    monitor_count=$(echo "$connected" | grep -cve '^\s*$')

    echo "$connected" >~/tmp/monitor-disable.log

    if [ "$monitor_count" -gt 1 ]; then
        echo "disabling monitor" >~/tmp/monitor-enable.log
        hyprctl keyword monitor "eDP-1,disabled"
    fi
}

monitorRemoved() {
    sleep 1
    connected=$(hyprctl monitors | grep "Monitor" | awk '{print $2}')
    monitor_count=$(echo "$connected" | grep -cve '^\s*$')

    echo "$connected" >~/tmp/monitor-enable.log

    if [ "$monitor_count" -eq 0 ]; then
        echo "enabling monitor" >~/tmp/monitor-enable.log
        hyprctl keyword monitor "eDP-1,3840x2400@60.0,0x0,2.0"
        echo "monitor enabled" >>~/tmp/monitor-enable.log
    fi
}

handle() {
    case $1 in
    monitorremoved*) monitorRemoved ;;
    monitoradded*) monitorAdded ;;
    esac
}

socat -U - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
