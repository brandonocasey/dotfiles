---
name: llm-tools
description: Check and install command-line tools that an LLM workflow requires, on the local host or a requested SSH host, with Homebrew.
---

Resolve `scripts/ensure-tools.sh` against this skill's directory, then run it with Bash.
With no tool names, it
checks or installs the core set: Git, jq, ripgrep, Python 3, GitHub CLI,
chezmoi, and Node.js.

```sh
bash scripts/ensure-tools.sh --check
bash scripts/ensure-tools.sh
bash scripts/ensure-tools.sh --remote user@host --check
bash scripts/ensure-tools.sh --remote user@host shellcheck shfmt
bash scripts/ensure-tools.sh pdftotext=poppler
```

Run `--check` first and report its result. Installation is allowed only when the
user asked to install or set up tools. Use `--remote` only for a host the user
named. The remote connection uses batch mode, disables configured remote
commands, and does not forward credentials.

The helper checks the current `PATH`, `~/.local/bin`, `~/bin`, and standard
Homebrew prefixes. It installs only missing requested formulas. It does not
auto-update Homebrew, upgrade an already installed requested formula, clean up,
remove packages, start services, install Homebrew, or copy login files or
credentials. Homebrew can still install or change dependencies required by a
new formula. If Homebrew is missing, report it as the prerequisite instead of
bootstrapping it. On a root host with `/root/bin/brew`, the helper uses that
wrapper instead of invoking Homebrew as root.

Use `--list` to see built-in tool names and their Brew formulas. For another
tool, pass `COMMAND=FORMULA` only after `brew info <formula>` or official Brew
documentation verifies the command-to-formula mapping. Keep a tap-qualified
formula tap-qualified.
