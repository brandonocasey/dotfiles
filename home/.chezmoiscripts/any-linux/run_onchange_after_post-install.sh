#!/usr/bin/env bash
export PATH="$PATH:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"

echo "Setting up ssh keys via bitwarden"
bw login
bw sync
export BW_SESSION="$(bw unlock --raw)"
echo "$BW_SESSION"

TEMP="$(mktemp -d)"
mkdir -p "$TEMP"
cd "$TEMP"

sudo -v
mkdir -p "$HOME/.ssh"

sudo chmod 700 "$HOME/.ssh"

for a in "brandonocasey-github-auth" "brandonocasey-github-auth.pub" "brandonocasey-github-sign" "brandonocasey-github-sign.pub"; do
  bw get attachment "$a" --itemid 0608e72b-a25b-4b7d-ad72-b12101687d21
  sudo mv "$TEMP/$a" "$HOME/.ssh/$a"

  if echo "$a" | grep -q '.pub'; then
    sudo chmod 644 "$HOME/.ssh/$a"
  else
    sudo chmod 600 "$HOME/.ssh/$a"
  fi
done

rm -rf "$TEMP"
