#!/bin/env zsh

THEME_URL="romkatv/powerlevel10k"
THEME_NAME="powerlevel10k"

# create plugin directory if not exists
[ ! -d "$PLUGINDIR" ] && mkdir -p $PLUGINDIR

# fetch plugin if not exists
[ ! -f "$PLUGINDIR/$THEME_NAME/$THEME_NAME.zsh-theme" ] && git clone "https://github.com/$1" $ZDOTDIR/.zsh_plugins/$THEME_NAME

source "$PLUGINDIR/$THEME_NAME/$THEME_NAME.zsh-theme"
