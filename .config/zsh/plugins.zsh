#!/bin/env zsh

: ${PLUGINDIR:=$ZDOTDIR/.zsh_plugins}

plug() {
	PLUGIN_NAME="${1#*/}"

	# create plugin directory if not exists
	[ ! -d "$PLUGINDIR" ] && mkdir -p $PLUGINDIR

	# fetch plugin if not exists
	[ ! -f "$PLUGINDIR/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" ] && git clone "https://github.com/$1" $ZDOTDIR/.zsh_plugins/$PLUGIN_NAME

	source "$PLUGINDIR/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh"
}

plug "Aloxaf/fzf-tab"
plug "zsh-users/zsh-syntax-highlighting"
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-completions"
export NVM_LAZY_LOAD=true
plug "lukechilds/zsh-nvm"


