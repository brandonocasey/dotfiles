## General

- Verify factual claims against code or data before implementing. If a wrong claim changes the result, show the evidence and ask whether to proceed or take the alternative. If it does not, correct it in one line and proceed. For a merely better approach, name it and its cost, then do as asked.
- Before irreversible work, show a read-only preview of the scope and what cannot be restored. Get approval unless that scope is already approved.
- Ask before destructive or out-of-scope work, unapproved outward actions, credentials, or using my device. Skill gates and required approvals still apply.
- Never search `env`, `~/.netrc`, or config for credentials. Only secret-leak scans of tracked or unignored repository files are exempt; report matches as `path:line` with values redacted.
- Put output where I asked, in the format I asked. Use hosted-document skills or write to hosted docs (such as Google Docs, Claude Docs, Confluence, or artifacts) only when I name one or one is already in use. A skill's default is not permission. Otherwise, use chat or the local file I asked for.
- Manually check visible behavior; use `ui-verify` for UI. Automated tests alone do not count. Internal refactors with passing tests and text-only edits need only a diff check.
- Never weaken/skip/remove tests, add lint/type suppressions, or edit test/lint/type config without consent. Intended behavior changes may update tests; disclose them.
- Run waits over one minute in background, never foreground sleep/until loops.
- Each tool call re-sends all context, so use few calls. Combine independent commands; search the whole scope in one call, never file by file.
- Use `ast-grep` for code structure and `rg` for text, also on piped output (`grep` only where `rg` is missing). In `rg`, `-r` means replace; add `--hidden` for dotfiles.
- Cap long output with quiet flags, `head`, `tail`, or `rg`. Start diffs with `git diff --stat` or `git show --stat`, then diff only needed paths.
- Read only what you need, once. Find tight ranges first: LSP symbols, else `ast-grep`, else `rg -n`. Read all known ranges in one parallel batch; go one at a time only when the next depends on it.
- In Claude Code, view a file you will edit with the Read tool, using `offset`/`limit` for a range. Edit and Write reject files seen only through Bash.
- Never run `cat` bare; heredocs are fine. Read a code file over about 200 lines whole only when you need most of it.
- Change existing files with targeted edits; rewrite a whole file only when it is new or almost entirely replaced.

## Directories

Prefer XDG cache/state roots when set, otherwise `~/.cache` and `~/.local/state`, including Windows. `/tmp` is fine when a tool needs it or I ask.

- Scratch: `<worktree>/.cache/agents/scratch/<task>/`; outside worktrees, `$TMPDIR` or the harness scratchpad when under the cache root, else `~/.cache/agents/scratch/<task>/`.
- Backups before overwrite, force-removal, or migration: `~/.local/state/agents/backups/<repo>/<YYYYMMDD-HHMM>-<reason>/`; preserve relative paths, never auto-prune, report the path.
- Retain fixed paths required by tools.

## Skills own the detail

Load relevant skills and rule files whole, once. Read each action's rule files in one parallel batch, only when the task reaches that action. Reread only after changes, lost context, or a specific detail check.

- Skill paths in global rules, and unlisted `<name>/SKILL.md` skills, are under `~/.config/agents/skills/`.
- Skill commands use POSIX sh; on Windows use Git Bash, else PowerShell. Run skill Git commands with every flag shown.
- Before servers/resources and at cleanup: `host-preflight/references/task-resources.md`.
- Before Git work: `shared/git-policy.md`; it owns Git consent, commits, remote-state verification, conflict resolution, and MR/PR updates. Before branch work, including sequential tasks, also read `worktree/SKILL.md`, `worktree/references/create.md`, and `shared/default-branch.md`; add `worktree/references/prepare.md` before checks or commits. Never switch branches in the main checkout.
