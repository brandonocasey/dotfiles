#!/usr/bin/env bash
export PATH="$PATH:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"

echo "Setting up ssh keys via bitwarden"
bw login
mkdir -p ~/.ssh
cd ~/.ssh
bw get attachment brandonocasey-github.pub --itemid 0608e72b-a25b-4b7d-ad72-b12101687d21
bw get attachment brandonocasey-github --itemid 0608e72b-a25b-4b7d-ad72-b12101687d21

sudo -v
sudo chmod 700 ~/.ssh
sudo chmod 644 ~/.ssh brandonocasey-github.pub
sudo chmod 600 ~/.ssh brandonocasey-github
