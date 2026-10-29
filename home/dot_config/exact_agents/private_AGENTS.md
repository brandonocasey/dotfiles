## General

- Verify factual claims against code or data before implementing. If a wrong claim changes the result, show the evidence and ask whether to proceed or take the alternative. If it does not, correct it in one line and proceed. For a merely better approach, name it and its cost, then do as asked.
- Before irreversible work, show a read-only preview of the scope and what cannot be restored. Get approval unless that scope is already approved.
- Ask before destructive work, unapproved outward actions, credentials, or using my device. Ask before out-of-scope work unless a follow-up rule covers it. Skill gates and required approvals still apply.
- Run commands yourself; hand me one only when you cannot run it (interactive login, blocked action). Never ask me to confirm work I requested. Before handing me a command or script, test it: check syntax (`sh -n`), that tools and paths exist, and run any safe part.
- Never search `env`, `~/.netrc`, or config for credentials. Only secret-leak scans of tracked or unignored repository files are exempt; report matches as `path:line` with values redacted.
- Put output in chat or where I asked, in the format I asked. Use hosted-document skills or write to hosted docs (such as Google Docs, Claude Docs, Confluence, or artifacts) only when I name one or one is already in use; a skill's default is not permission.
- Never put Claude session or artifact links (claude.ai/artifact, claude.ai/code, session URLs) in public-facing text: MR/PR titles and descriptions, comments, commits, docs, issues, or release notes. Attach the content itself (images, logs, text) instead.
- Manually check visible behavior; use `ux-verify` for UI and other user-facing output. Automated tests alone do not count. Internal refactors with passing tests and text-only edits need only a diff check.
- Never weaken/skip/remove tests, add lint/type suppressions, or edit test/lint/type config without consent. Intended behavior changes may update tests; disclose them.
- Waiting (in Claude Code a hook moves foreground waits to the background and blocks the kills; use the replacement first time):
  - `sleep` of 20s+, a loop that sleeps, or `sleep N; cat log` of any length → run the job with `run_in_background: true` and a log file, then stop until its exit notification.
  - `agt wait`, `agt ci wait`, `gh run watch`, or a long sub-agent call in the foreground → same command with `run_in_background: true`, then stop.
  - Commands likely to take over ~20s (test suites, builds, browser runs) start in the background; short commands stay foreground.
  - `pkill`, `killall`, or `pgrep … | xargs kill` by name → `kill` the PID you saved at start, or `pkill -F <pidfile>`. A name or path also stops other sessions' processes. For a process you did not start, list it with `pgrep -fl '[n]ame'`, then kill it by number in a separate call.
  - `pgrep -f name` → `pgrep -f '[n]ame'`, with no other unbracketed copy of the name in the command.
  - When stopping to wait, say what you are waiting on and the expected duration.
- Never sit idle waiting. When remaining steps must wait a long time (pipelines, reviews, slow runs), hand them off to one or more fitting agents per `sub-agents`; meanwhile, review, do other tasks, and make fixes. When a push is authorized, push as soon as local checks pass so CI starts early.
- Use `agent-probe` for headless usage or A/B probes. In other `claude -p` runs, keep `ToolSearch` in any `--tools` list. When tool search is off (`ENABLE_TOOL_SEARCH=false` in env or settings, a custom `ANTHROPIC_BASE_URL`, or ToolSearch denied), add `--strict-mcp-config`. Without these, every connector tool is sent in full: about 600k tokens per call.
- Each tool call re-sends all context, so use few calls. Combine independent commands; search the whole scope in one call, never file by file. For a named symbol, find references with `rg -n '\bName\b'` and the definition with `rg -n '(fn|struct|enum|trait|type|const|class|interface) Name\b'`. Then read only those ranges, once, all known ranges in one call; go one at a time only when the next depends on it. Still read all needed context: the whole function, its callers, and the contracts it depends on. Chain dependent steps whose output you need not inspect into the call that uses them with `&&`: `mkdir`, `cp`, `rm`, file writes, and `git add` before the command that needs them. Use absolute paths or `git -C` rather than a leading `cd`, which triggers permission checks in compound commands.
- Use `rg` for code and text, also on piped output (`grep` only where `rg` is missing). Use `ast-grep` only when text matches would be ambiguous, with output trimmed to file:line (`--json=stream | jq`). In `rg`, `-r` means replace; add `--hidden` for dotfiles.
- Cap long output with quiet flags, `head`, `tail`, or `rg`. Start diffs with `git diff --stat` or `git show --stat`, then diff only needed paths.
- When compacting, keep the full list of changed files, the test and check commands, and scratch file paths.
- Read ranges with `sed -n` or `rg`; the file-read tool's line-numbered output costs more tokens. In Claude Code, use the file-read tool for files you will edit: Edit and Write reject files seen only through Bash. Use `cat` to load whole skill files; heredocs are fine. Read a code file over about 200 lines whole only when you need most of it.
- Change existing files with targeted edits; rewrite a whole file only when it is new or almost entirely replaced.
- zsh: no words starting with `=` (use `printf '--- %s\n'`); write `${B}:refs/...` and quote refspecs.
- Delete your own task dir at task end; `agt cleanup` handles leftovers. Delete with literal paths or `find <dir> -delete`, never `rm` on a variable or glob.
- Run `chezmoi apply/add/re-add` as a standalone command, never chained. Run MR/PR approve and merge as separate commands. Do not append `; echo rc=$?` to commands.
- To find a past session, run `agt sessions search` first.
- If a stop-hook objection repeats and needs my decision, reply with the decision needed and call no tools.

## Directories

Prefer XDG cache/state roots when set, otherwise `~/.cache` and `~/.local/state`, including Windows. Keep fixed paths a tool requires; use `/tmp` only when a tool needs it or I ask.

- Scratch: `<worktree>/.cache/agents/scratch/<task>/`; outside worktrees, `$TMPDIR` or the harness scratchpad when under the cache root, else `~/.cache/agents/scratch/<task>/`.
- Backups before overwrite, force-removal, or migration: `~/.local/state/agents/backups/<repo>/<YYYYMMDD-HHMM>-<reason>/`; preserve relative paths, never auto-prune, report the path.

## Skills own the detail

Load relevant skills and rule files whole, once. Read each action's rule files in one parallel batch, only when the task reaches that action. Reread only after changes, lost context, or a specific detail check.

- Skill paths in global rules, and unlisted `<name>/SKILL.md` skills, are under `~/.config/agents/skills/`.
- Skill commands use POSIX sh; on Windows use Git Bash, else PowerShell. Run skill Git commands with every flag shown.
- Before servers/resources and at cleanup: `host-preflight/references/task-resources.md`.
- Before Git work: `shared/git-policy.md`; it owns Git consent, commits, remote-state verification, conflict resolution, and MR/PR updates. Before branch work, including sequential tasks, also read `worktree/SKILL.md`, `worktree/references/create.md`, and `shared/default-branch.md`; add `worktree/references/prepare.md` before checks or commits. Create and set up worktrees yourself with `agt worktree create <branch>` (add `--prepare` per `worktree/references/prepare.md`), never through a `cheap` agent. Never switch branches in the main checkout.
