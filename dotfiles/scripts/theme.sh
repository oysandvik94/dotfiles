#!/usr/bin/env bash

current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme)
if [[ $current_theme == *"dark"* ]]; then
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' && gsettings set org.gnome.desktop.interface color-scheme 'default' && gsettings set org.gnome.desktop.interface icon-theme 'Reversal-blue-light'
    source ~/dotfiles/dotfiles/.config/zsh/colors_light.zsh
    notify-send "Setting light theme"
else
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' && gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' && gsettings set org.gnome.desktop.interface icon-theme 'Reversal-blue-dark'
    source ~/dotfiles/dotfiles/.config/zsh/colors.zsh
    notify-send "Setting dark theme"
fi

~/dotfiles/dotfiles/.config/waybar/scripts/update_theme.sh

# this should work for all terms:
for TERM in /dev/pts/[0-9]*; do
    if [[ -O $TERM ]]; then
        {
            printf "\\033]10;rgb:%s\\033\\\\" "$COLOR_BACKGROUND"
            printf "\\033]11;rgb:%s\\033\\\\" "$COLOR_BACKGROUND"
        } >"$TERM"
    fi
done
