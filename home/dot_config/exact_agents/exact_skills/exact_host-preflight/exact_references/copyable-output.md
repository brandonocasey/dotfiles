# Copyable output

Read when preparing commands or text the user must copy.

- Make copyable commands, comments, commit messages, and snippets safe for terminals wrapping at about 80 characters:
  - Show every proposal's exact final wording in chat, even with a copy file. Put longer text in the Copy directory's `<task>.md`.
  - For commands I must run, follow AGENTS.md: one short command, or a self-deleting scratch script handed over as `! sh <script>`.
  - Give one usage line with the resolved Copy directory: `copy <Copy>/<task>.md`. `copy` uses OSC 52 over SSH and from `!` commands. Never suggest `pbcopy` or `clip`. Delete copy files only after observing successful use or my report of use.
  - Put short items in separate fenced blocks, each containing one line, with no extra content or backslash continuations.
