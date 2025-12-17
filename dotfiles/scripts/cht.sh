#! /usr/bin/env bash

HISTORY_FILE=$HOME/.tmux_chtsh_history

function _list() {
    curl -s https://cht.sh/:list | grep -vE '(^:|[\/\[])'
}

function _select_item() {
    selected=$(cat <(tac $HISTORY_FILE 2>/dev/null | grep "\S" || true) <(_list) | awk '!x[$0]++' | fzf)

    echo "${selected}" >> $HISTORY_FILE

    echo "${selected}"
}

function _compact_history_file() {
    local temp_file=$(mktemp)
    tac $HISTORY_FILE | awk '!x[$0]++' > $temp_file
    tac $temp_file > $HISTORY_FILE
    rm $temp_file
}

selected=$(_select_item; _compact_history_file)

if [[ -z $selected ]]; then
    exit 0
fi

read -p "Enter Query: " query

query=`echo $query | tr ' ' '+'`

if [[ -z "${query}" ]]; then
    tmux neww bash -c "echo \"curl -s cht.sh/$selected\" & curl -s cht.sh/$selected | less -r"
else
    tmux neww bash -c "echo \"curl -s cht.sh/$selected/$query/\" & curl -s cht.sh/$selected/$query | less -r"
fi

