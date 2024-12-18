# Auto-completion
# ---------------
source <(fzf --zsh)

# Key bindings
# ------------
# COMPLETION_FILE="/usr/share/fzf/completion.zsh"
# test -f $COMPLETION_FILE && source $COMPLETION_FILE
# COMPLETION_FILE="/usr/share/bash-completion/completions/fzf"
# test -f $COMPLETION_FILE && source $COMPLETION_FILE

export FZF_DEFAULT_OPTS="
--color=fg:$COLOR_FOREGROUND,bg:$COLOR_BACKGROUND,hl:$COLOR_PRIMARY
--color=border:$COLOR_OK,header:$COLOR_SECONDARY,gutter:$COLOR_BACKGROUND
--color=spinner:#56c177,info:$COLOR_SECONDARY,separator:$COLOR_BAD
--color=pointer:$COLOR_PRIMARY,marker:$COLOR_BAD,prompt:$COLOR_PRIMARY"
