#!/usr/bin/env bash
export PATH="$PATH:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"

echo "Setting up ssh keys via bitwarden"
bw login
bw sync
export BW_SESSION=$(bw unlock --raw)

TEMP="$(mktemp -d)"
mkdir -p "$TEMP"
cd "$TEMP"

ATTACHMENTS=(brandonocasey-github-auth brandonocasey-github-auth.pub brandonocasey-github-sign brandonocasey-github-sign.pub)

for a in "${ATTACHMENTS[@]}"; do
  bw get attachment "$a" --itemid 0608e72b-a25b-4b7d-ad72-b12101687d21
done

sudo -v
mkdir -p ~/.ssh

sudo mv "$TEMP"/* "$HOME/.ssh/"
sudo chmod 700 "$HOME/.ssh"

sudo find "$TEMP/.ssh" -name '*.pub' -print0 |
    while IFS= read -r -d '' pubkey; do
      privkey="${pubkey/.pub/}"
      if [ -f "$privkey" ]; then
        sudo chmod 600 "$privkey"
        sudo mv -fv "$privkey" "$HOME/.ssh/$(basename "$privkey")"
      fi
      sudo chmod 644 "$pubkey"
      sudo mv -fv "$pubkey" "$HOME/.ssh/$(basename "$pubkey")"
    done

rm -rf "$TEMP"
