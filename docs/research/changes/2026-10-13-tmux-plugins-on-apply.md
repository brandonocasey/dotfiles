# tmux plugins installed on apply

- Status (2026-11-06): current. `home/.chezmoiscripts/any-linux/run_onchange_after_29-tmux-plugins.sh.tmpl` runs tpm's `install_plugins` and `update_plugins all`; since 2026-10-16 it re-runs only when the `set -g @plugin` lines of `tmux.conf` change.
- Topic: Incidental doc use (the change was not driven by the source)
- Related: [Tmux hyperlink passthrough for Ghostty](2026-10-15-tmux-hyperlinks-ghostty.md)

## Change
tmux plugins are installed and updated on `chezmoi apply`. The change is not doc-backed: the Claude Code fullscreen docs were used only to diagnose why the user saw no click-to-scroll-to-bottom button on a headless machine.

## History
- 2026-10-13 — session c1cbdea2 (work repo): user: "on a headless machine I don't see a click to scroll back to bottom in claude code, also tapping on my terminal on mobile doesn't seem to work when click to scroll works with a mouse." The assistant checked the docs: the button exists only in fullscreen mode; run `/tui` and `/tui fullscreen`; keep `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN` unset; with tmux, `set -g mouse on`. The user then asked "check my tmux config for mouse on", "are tmux plugins installed automatically using chezmoi? maybe that's the issue? it's in fullscreen", "tmux does not take the scroll", and "can we get chezmoi to auto install and update".
- 2026-10-13 — commit `14786152 build(tmux): install and update plugins on apply`: adds `run_onchange_after_29-tmux-plugins.sh.tmpl` and a short README note in the Tmux section. `chezmoi apply` was skipped in the session because the change is a script; the assistant had run it by hand earlier.
- 2026-10-16 — commit `d4ff8d65 build(tmux): install plugins only when the list changes`: the script's run-on-change hash now covers only the plugin lines, so other `tmux.conf` edits do not trigger it (no commit body; reason inferred from the script comment "Hashes only the plugin list, so other tmux.conf edits skip this").
- 2026-11-06 — status check: script present and unchanged since d4ff8d65.

## Results
No measurement. The session ran the script by hand; it did not report whether missing plugins were the cause of the missing scroll behavior. The reply to the mobile question was explicitly unverified: "The docs don't cover mobile terminals. Unverified: many phone apps send a tap as a cursor move, not a mouse click." Suggested workarounds: `Ctrl+End`, a `scroll:bottom` keybinding, or `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1`. The final next step was for the user to run `chezmoi update` and `claude --version` on the headless machine to check for an old Claude Code build; the outcome was not found in the session.

## Sources
- [Claude Code fullscreen docs](https://code.claude.com/docs/en/fullscreen) — used only to diagnose scroll-to-bottom; the docs "don't cover mobile terminals".

## Evidence
Incidental. Session c1cbdea2 (2026-10-13). The fetch method for the docs page was not recorded; no quotes beyond the one above were kept.
