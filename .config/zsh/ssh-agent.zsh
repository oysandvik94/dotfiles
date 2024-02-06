#!/usr/bin/env zsh

# Script to initialize SSH keys with keychain, now working in utter silence

# Search for SSH key files in the ~/.ssh directory
fd . $HOME/.ssh | while read -r fname; do
  # Check if the file name matches either id_ed or id_rsa
  if [[ $fname =~ "id_ed" || $fname =~ "id_rsa" ]]; then
    # Skip public key files
    if [[ $fname =~ ".pub" ]]; then
      continue
    fi

    # Add the key to the keychain, now in silence
    eval "$(keychain --quiet --eval --agents ssh "$fname")" &>/dev/null
  fi
done
