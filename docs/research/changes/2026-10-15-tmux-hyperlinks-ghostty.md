# Tmux hyperlink passthrough for Ghostty

- Status (2026-11-06): current. `home/dot_config/tmux/tmux.conf` line 41: `set-option -ga terminal-features "xterm-ghostty:RGB:hyperlinks"`, with the comment "tmux 3.7c does not auto-detect Ghostty, so OSC 8 links are stripped without this". Re-checked in the file on 2026-11-06; not re-tested in a live Ghostty window.
- Topic: Terminal and UI
- Related: [Statusline links, ports and agent rows](2026-10-16-statusline-links-ports.md), [tmux plugins on apply](2026-10-13-tmux-plugins-on-apply.md)

## Change
tmux passes OSC 8 hyperlinks through when the terminal type is `xterm-ghostty`. The existing line only enabled `hyperlinks` for `xterm-256color` (set in 2026-08-03 commit `e3952fdc`, whose subject lists many files). Ghostty reports `xterm-ghostty`, and tmux 3.7c does not recognize it on its own, so tmux stripped links that programs print.

Half of the user's problem is not fixable in config: with `mouse on`, tmux takes the mouse and Ghostty shows links only while the modifier is held (Cmd+Shift). Ghostty's maintainers have said they will not change this; the other way out is turning tmux mouse off.

## History
- 2026-08-03 — `e3952fdc` (subject is a file list) added `set-option -ga terminal-features "xterm-256color:RGB:hyperlinks"`.
- 2026-10-15 — session 0d03d739: user: "tmux doesn't seem to show clickable links on mouseover like i'd expect, how can we fix this?". The assistant read tmux's feature table and Ghostty source, added `xterm-ghostty` to the live config, and tested with a test tmux server that loaded the setting.
- 2026-10-15 — commit `b0c8a1b8 fix(tmux): pass hyperlinks through in ghostty`: adds the `xterm-ghostty` line and comment. Applied and pushed in the same session via dotfiles-sync.
- 2026-11-06 — no later commit touched this line (`git log -S'xterm-ghostty'` finds only `b0c8a1b8`).

## Results
No measurement in a live Ghostty window. The assistant said: "I couldn't test it in your Ghostty window". It tested only that a test tmux server loaded the new setting, and gave a repro: `printf '\e]8;;https://example.com\e\\example link\e]8;;\e\\\n'` should print a link that underlines on Cmd+Shift hover after reloading the config (prefix then `r`) and detaching and reattaching.

Not found: any later session where the user confirmed or denied that links work after this change (searched the 0d03d739 transcript and commit history).

## Sources
- [tmux feature table (tty-features.c)](https://raw.githubusercontent.com/tmux/tmux/master/tty-features.c) — which terminals get the `hyperlinks` feature.
- [Ghostty link hover with mouse reporting (mirror commit)](https://git.uoc.run.place/Applied-Software/ghostty/commit/318641f5a19699cfdace5dfe5afc3051fd681722) — hover works under mouse reporting only with the modifier.
- [claudeissues.com #90026](https://claudeissues.com/issue/90026-feature-fullscreen-tui-show-hover-feedback-on-links) — fullscreen TUI link hover.

## Evidence
Read from source and cited with a printf repro line in the reply. Session 0d03d739 (2026-10-15). The two Ghostty and issue pages were found by the session; whether each was fetched in full or only seen as a search result was not recorded.
