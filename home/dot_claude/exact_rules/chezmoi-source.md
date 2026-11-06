---
paths:
  - "**/.chezmoi*"
  - "**/.chezmoi*/**"
  - "**/dot_*"
  - "**/dot_*/**"
  - "**/private_dot_*"
  - "**/private_dot_*/**"
  - "**/modify_*"
  - "**/private_Library/**"
---
# Chezmoi sources

A source change runs on every host at its next `chezmoi apply`, including hosts that applied older versions.

- Edit the source, then apply. Find a deployed file's source with `chezmoi source-path <file>`; an edit to only the deployed file is reverted by the next apply.
- When you delete or rename a source outside an `exact_` directory, add the old target to `.chezmoiremove`; otherwise hosts that applied it keep the file.
- Before making a directory `exact_`, list what else writes into it on each OS. Apply deletes every unmanaged file there; add `.chezmoiignore` entries for the ones to keep.
- Number prefixes do not order scripts across OS subdirectories. Run `chezmoi apply --dry-run -v` on each OS and read the script order it prints before relying on it.
- A `run_once_` or `run_onchange_` script that exits 0 is recorded as done and does not run again until its content changes; a nonzero exit stops this apply and retries on the next. Choose per step, and print what the user must do.
- Pin a tool version (mise, Brewfile) only after that release is published.
