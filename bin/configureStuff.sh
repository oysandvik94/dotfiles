#!/usr/bin/env bash

echo "Setting default shell to zsh"
echo
ZSH_PATH=/usr/bin/zsh
test "$SHELL" = "$ZSH_PATH" || chsh -s "$ZSH_PATH"

echo "Creating ssh directory"
echo
mkdir -p ~/.ssh

echo "Installing tmux plugin manager"
[ ! -f "$HOME/.tmux/plugins/tpm/tpm" ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 
