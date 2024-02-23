sudo -v
echo "Installing pacman packages..."
while IFS= read -r package; do
        pacman -Qs "$package" &> /dev/null && continue

        echo "$package is not installed, doing it now..."
        sudo pacman -S -q --noconfirm "$package" || exit 1
done < "$BIN_DIR"/pacman_packages.txt

sudo -v
echo "Installing AUR packages..."
while IFS= read -r package; do
        yay -Qs "$package" &> /dev/null && continue

        echo "$package is not installed, doing it now..."
        yay -S -q --noconfirm "$package" || exit 1
done < "$BIN_DIR"/aur_packages.txt
