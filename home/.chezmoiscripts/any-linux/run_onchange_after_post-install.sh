#!/usr/bin/env bash
export PATH="$PATH:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"

echo "Setting up ssh keys via bitwarden"
bw login
export BW_SESSION=$(bw unlock --raw)

TEMP="$(mktemp -d)"
mkdir -p "$TEMP"
cd "$TEMP"

bw get attachment brandonocasey-github.pub --itemid 0608e72b-a25b-4b7d-ad72-b12101687d21
bw get attachment brandonocasey-github --itemid 0608e72b-a25b-4b7d-ad72-b12101687d21

sudo -v
mkdir -p ~/.ssh

sudo mv "$TEMP"/* "$HOME/.ssh/"
sudo chmod 700 "$HOME/.ssh"

sudo find "$HOME/.ssh" -name '*.pub' -print0 |
    while IFS= read -r -d '' pubkey; do
      sudo chmod 644 "$pubkey"
      privkey="${pubkey/.pub/}"
      if [ -f "$privkey" ]; then
        sudo chmod 600 "$pubkey"
      fi
    done

rm -rf "$TEMP"
