## General

- Verify factual claims against code/data before implementation. If a wrong claim changes the result, show evidence and ask: proceed anyway or take the alternative? Otherwise correct it in one line and proceed. For a merely better approach, name it and its cost, then proceed as asked.
- Before irreversible work, show a read-only preview: scope and what cannot be restored. Get approval unless that scope is already approved. Ask for destructive/out-of-scope work, unauthorized outward actions, credentials, my device, or required approvals. Skill gates apply. Settle evidence-based questions yourself.
- Never search `env`, `~/.netrc`, or config for credentials. Only secret-leak scans of tracked or unignored repository files, including the chezmoi source, are exempt; report their matches as `path:line` with values redacted.
- Preserve destination and format. Hosted-document skills/writes require an explicit or established hosted destination; defaults grant no authority. Otherwise use chat or the requested local file.
- Manually check visible behavior; use `ui-verify` for UI. Automated tests alone do not count. Internal refactors with passing tests and text-only edits need only a diff check. Attach UI evidence to PRs unless text/diff suffices.
- Never weaken/skip/remove tests, add lint/type suppressions, or edit test/lint/type config without consent. Intended behavior changes may update tests; disclose them.
- Run waits over one minute in background, never foreground sleep/until loops.
- Every tool call re-sends the whole context, including everything read so far. Use fewer calls: combine independent commands. Search the whole scope with one `rg`, also on piped output, never file by file. Use `grep` only where `rg` is missing. In `rg`, `-r` means replace; add `--hidden` for dotfiles.
- Never run `cat` bare: narrow it with `rg`, `head`, `tail`, or `sed -n`; heredocs are fine. Never `sed` or Read a whole file over about 200 lines unless you need most of it. Never re-read unchanged content. Start diffs with `git diff --stat` or `git show --stat`, then diff only the paths you need. Cap long output with quiet flags, `head`, `tail`, or `rg`.
- Change existing files with Edit. Use Write only for new files or near-total rewrites.
- Plan reads before reading. Get exact ranges first from the LSP tool's document symbols, or `ast-grep` when no server covers the language, else `rg -n`. Then read all known or likely ranges in one parallel batch, or one multi-file `sed -n` call. Read one range at a time only when the next depends on its result. Keep ranges tight; guess narrow, not wide.
- Read rule files whole, once; line ranges and the 200-line limit apply to code only. When an action needs rule files, read its whole set in one parallel batch; do not read ahead for actions the task may not reach.
- Sub-agents do only assigned work; skip review, commits, cleanup, and recaps unless assigned.

## Directories

Never use OS temporary directories, even if instructed. Use XDG cache/state roots when set, otherwise `~/.cache` and `~/.local/state`, including Windows.

- Scratch: `<worktree>/.cache/agents/scratch/<task>/`; outside worktrees, `$TMPDIR` or the harness scratchpad when inside that cache root, else `~/.cache/agents/scratch/<task>/`.
- Backups before overwrite, force-removal, or migration: `~/.local/state/agents/backups/<repo>/<YYYYMMDD-HHMM>-<reason>/`; preserve relative paths, never auto-prune, report the path.
- Create missing parents; retain fixed paths required by tools.

## Skills own the detail

Load relevant skills once; reread only after changes, lost context, or a specific detail check. Skill paths in any global rules, and unlisted `<name>/SKILL.md` skills, are under `~/.config/agents/skills/`. Skill commands use POSIX sh; Windows uses Git Bash, otherwise PowerShell. Run skill Git commands with every flag shown.

- Before servers/resources and at cleanup: `host-preflight/references/task-resources.md`.
- Before branch work, including sequential tasks: `worktree`. Never switch branches in the main checkout.
- Before Git work: `shared/git-policy.md`. It owns Git consent, commits, remote-state verification, conflict resolution, and MR/PR updates.
