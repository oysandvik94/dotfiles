#!/usr/bin/env bash

WAYBAR_DIR=$HOME/.config/waybar

sed -e "s/PRIMARY_PLACEHOLDER/${COLOR_PRIMARY}/g" \
    -e "s/SECONDARY_PLACEHOLDER/${COLOR_SECONDARY}/g" \
    -e "s/TERTIARY_PLACEHOLDER/${COLOR_TERTIARY}/g" \
    -e "s/OK_PLACEHOLDER/${COLOR_OK}/g" \
    -e "s/BAD_PLACEHOLDER/${COLOR_BAD}/g" \
    -e "s/FOREGROUND_PLACEHOLDER/${COLOR_FOREGROUND}/g" \
    -e "s/BACKGROUND_PLACEHOLDER/${COLOR_BACKGROUND}/g" \
    $WAYBAR_DIR/template.css > $WAYBAR_DIR/style.css


pkill waybar
waybar &> /dev/null &
