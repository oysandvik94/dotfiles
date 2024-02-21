#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Launch bar only if there are multiple displays
if type "xrandr"; then
  if [ "$(xrandr --query | grep ' connected' | wc -l)" -gt 1 ]; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
      MONITOR=$m polybar --reload --config="~/.config/polybar/config.ini" mybar &
    done
  else
    polybar --reload --config="~/.config/polybar/config.ini" mybar &
  fi
else
  polybar --reload --config="~/.config/polybar/config.ini" mybar &
fi

echo "Bars launched..."

