---
paths:
  - "**/*.{sh,bash,zsh,fish}"
  - "**/*.{sh,bash,zsh,fish}.tmpl"
  - "**/{bin,scripts,.chezmoiscripts}/**"
  - "**/{executable,modify}_*"
  - "**/*{bashrc,bash_profile,zshrc,zshenv,zprofile}*"
  - "**/.docker/*"
---
# Shell scripts, hooks, startup files, and tool config

- Before handoff, run the script once from another directory under `env -i HOME="$HOME" PATH=/usr/bin:/bin`, with `/bin/bash` for a bash script (bash 3.2 and BSD tools on macOS), so it runs non-interactive with each variable it relies on unset. When the script writes under `HOME`, pass a temporary directory as `HOME` instead and delete it afterward. Do not put `$VAR` or `~` in a config file until you have checked that the tool expands them. Give an exported variable a specific name, and check what every child process does with it. Under `set -e`, give each command that can fail on a fresh machine (missing tool, unregistered plugin, unreleased version) a fallback or a stop with a clear message.
