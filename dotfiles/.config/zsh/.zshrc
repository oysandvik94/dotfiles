#!/usr/bin/env zsh
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


source $ZDOTDIR/plugins.zsh
source $ZDOTDIR/promptTheme.zsh
source $ZDOTDIR/aliases
source $ZDOTDIR/vim.zsh
source $ZDOTDIR/fzf.zsh


path+=("$HOME/.local/bin/scripts")
path+=("$HOME/.local/share/nvim/mason/bin")
path+=("/usr/local/go/bin")
path+=("$HOME/go/bin")


# Completion
autoload -U compinit; compinit
_comp_options+=(globdots) # With hidden files

# Directory stack
setopt AUTO_PUSHD           # Push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.

alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index;

export FZF_DEFAULT_OPTS="
--color=fg:#908caa,bg:#191724,hl:#ebbcba
--color=fg+:#e0def4,bg+:#26233a,hl+:#ebbcba
--color=border:#403d52,header:#31748f,gutter:#191724
--color=spinner:#f6c177,info:#9ccfd8,separator:#403d52
--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"

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

if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! -f "$SSH_AUTH_SOCK" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi


# export NVM_LAZY=1
# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
SDKMAN_DIR="/home/oysandvik/.sdkman" 
[[ -s "/home/oysandvik/.sdkman/bin/sdkman-init.sh" ]] && source "/home/oysandvik/.sdkman/bin/sdkman-init.sh"

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then 
  exec startx &>/dev/null 
fi

