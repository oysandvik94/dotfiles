# Auto-completion
# ---------------
source "/usr/share/fzf/key-bindings.zsh"

# Key bindings
# ------------
source "/usr/share/fzf/completion.zsh"

export FZF_DEFAULT_OPTS="
--color=fg:$COLOR_FOREGROUND,bg:$COLOR_BACKGROUND,hl:$COLOR_PRIMARY
--color=border:$COLOR_OK,header:$COLOR_SECONDARY,gutter:$COLOR_BACKGROUND
--color=spinner:#56c177,info:$COLOR_SECONDARY,separator:$COLOR_BAD
--color=pointer:$COLOR_PRIMARY,marker:$COLOR_BAD,prompt:$COLOR_PRIMARY"
