#!/usr/bin/env bash

echo "Setting default shell to zsh"
echo
ZSH_PATH=/usr/bin/zsh
test "$SHELL" = "$ZSH_PATH" || chsh -s "$ZSH_PATH"

echo "Creating ssh directory"
mkdir -p ~/.ssh
