#!/bin/bash

main() {
	which yay &>/dev/null || install_yay
}

install_yay() {
	echo "Yay is not installed! Installing it in ~/bin now"
	echo
	mkdir -p "$HOME"/bin
	git clone https://aur.archlinux.org/yay.git "$HOME"/bin/yay
	cd "$HOME"/bin/yay || exit 1
	makepkg -si
}

main "$@"
