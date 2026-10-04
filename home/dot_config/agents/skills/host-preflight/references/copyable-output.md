# Copyable output

Read when preparing commands or text the user must copy.

- Make copyable commands, comments, commit messages, and snippets safe for terminals wrapping at about 80 characters:
  - Show every proposal's exact final wording in chat, even with a copy file. Put longer commands that I must run myself in the Copy directory's `run-<task>.sh`, and text in `<task>.md`.
  - Give one usage line with the resolved Copy directory: `bash <Copy>/run-<task>.sh` (Git Bash on Windows) or `copy <Copy>/<task>.md`. `copy` uses OSC 52 over SSH and from `!` commands. Never suggest `pbcopy` or `clip`. Delete copy files only after observing successful use or my report of use.
  - Put short items in separate fenced blocks, each containing one line, with no extra content or backslash continuations.
