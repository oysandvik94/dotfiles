#!/usr/bin/env bash
selected=$(cat ~/.local/bin/scripts/chtsh/.tmux-cht-languages ~/.local/bin/scripts/chtsh/.tmux-cht-custom ~/.local/bin/scripts/chtsh/.tmux-cht-command | fzf)
if [[ -z $selected ]]; then
	exit 0
fi

if [[ $selected == 'wiki' ]]; then
	tmux neww bash -c "zk edit --interactive"
	exit 0
fi

read -rp "Enter Query: " query

if [[ $selected == 'man' ]]; then
	tmux neww bash -c "man $query"
	exit 0
fi

if [[ $selected == 'tldr' ]]; then
	tmux neww bash -c "tldr $query --color always | less -R"
	exit 0
fi

if grep -qs "$selected" ~/.local/bin/scripts/chtsh/.tmux-cht-languages; then
	query=$(echo "$query" | tr ' ' '+')
	tmux neww bash -c "curl -s https://cht.sh/$selected/$query | less -R"
else
	tmux neww bash -c "curl -s https://cht.sh/$selected~$query | less -R"
fi
