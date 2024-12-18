#!/usr/bin/env bash

killall polybar

for m in $(polybar --list-monitors | cut -d":" -f1); do
  MONITOR=$m polybar --reload --config="~/.config/polybar/config.ini" mybar &
done

echo "Bars launched..."
