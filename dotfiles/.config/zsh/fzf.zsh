# Setup fzf
# ---------
if [[ ! "$PATH" == */home/oysandvik/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/oysandvik/.fzf/bin"
fi

# Auto-completion
# ---------------
source "/home/oysandvik/.fzf/shell/completion.zsh"

# Key bindings
# ------------
source "/home/oysandvik/.fzf/shell/key-bindings.zsh"

