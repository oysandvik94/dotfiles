export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export EDITOR="nvim"
export VISUAL="nvim"

export HISTFILE="$ZDOTDIR/.zhistory"    # History filepath
export HISTSIZE=10000                   # Maximum events for internal history
export SAVEHIST=10000                   # Maximum events in history file

# Man pages
export MANPAGER='nvim +Man!'

export PATH="$PATH:$HOME/.dotnet/tools"
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$PATH:$DOTNET_ROOT"
export W3M_DIR="$HOME/.local/state/w3m"

export WLR_NO_HARDWARE_CURSORS=1

export DOCKER_BUILDKIT=1

. "$HOME/.cargo/env"
