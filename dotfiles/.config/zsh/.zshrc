#!/usr/bin/env zsh

eval "$(starship init zsh)"

source $ZDOTDIR/plugins.zsh
source $ZDOTDIR/copilot.zsh
source $ZDOTDIR/aliases
test -f $ZDOTDIR/jobbaliases && source $ZDOTDIR/jobbaliases
source $ZDOTDIR/vim.zsh
source $ZDOTDIR/fzf.zsh
source $ZDOTDIR/zbell.sh
source $HOME/.zshenv
# source <(ng completion script) # This is slow, figure out how to make it fast

current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme)
if [[ $current_theme == *"dark"* ]]; then
    source ~/dotfiles/dotfiles/.config/zsh/colors.zsh
else
    source ~/dotfiles/dotfiles/.config/zsh/colors_light.zsh
fi


path+=("$HOME/.local/bin/scripts")
path+=("$HOME/.local/bin")
path+=("$HOME/.local/share/nvim/mason/bin")
path+=("$HOME/dotfiles/dotfiles/scripts")
path+=("/usr/local/go/bin")
path+=("$HOME/go/bin")
path+=("$HOME/jobbscript/")


# Completion
autoload -U compinit; compinit
_comp_options+=(globdots) # With hidden files

# Directory stack
setopt AUTO_PUSHD           # Push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.

# history

setopt inc_append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_space

alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index;

bindkey '\e.' insert-last-word

dotc() {
    if [ $# -eq 3 ]; then
    dotfiles commit -m "$1($2): $3"
    else
        echo "You shall not pass! The function requires exactly three parameters."
    fi
}

gcb() {
    if [ $# -eq 0 ]; then
        echo "Usage: gcb <repository>"
        return 1
    fi

    local repo_url="$1"
    local repo_name=$(basename "$repo_url" .git)

    git clone --bare "$repo_url" "$repo_name"
}

dota() {
    pushd $HOME >/dev/null
    dotfile=$(dotfiles diff --name-only | sort | fzf -m) && dotfiles add $dotfile
    popd >/dev/null 
}

autoautorandr() {
    autorandr --change
    $HOME/.config/polybar/launch.sh &
}

# if ! pgrep -u "$USER" ssh-agent > /dev/null; then
#     ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
# fi
# if [[ ! -f "$SSH_AUTH_SOCK" ]]; then
#     source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
# fi

eval $(keychain --eval --quiet id_ed25519)

# export NVM_LAZY=1
# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
SDKMAN_DIR="$HOME/.sdkman" 
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then 
        echo "Choose a WM

        1) i3
        2) hypr
        3) sway
        4) gnome
        -> "

        read option
        echo $option

        if [[ "$option" == "1" ]]; then
                exec startx &>/dev/null 
        fi

        if [[ "$option" == "2" ]]; then
                exec launchHypr.sh
        fi

        if [[ "$option" == "3" ]]; then
            export QT_QPA_PLATFORM=wayland
            export MOZ_ENABLE_WAYLAND=1
            export MOZ_WEBRENDER=1
            export XDG_SESSION_TYPE=wayland
            export XDG_CURRENT_DESKTOP=sway
            exec sway
        fi

        if [[ "$option" == "4" ]]; then
            exec gnome-session
        fi
fi
