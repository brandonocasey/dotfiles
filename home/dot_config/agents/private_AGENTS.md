## General

- Verify factual claims against code/data before implementation. If a wrong claim changes the result, show evidence and ask: proceed anyway or take the alternative? Otherwise correct it in one line and proceed. For a merely better approach, name it and its cost, then proceed as asked.
- Complete all authorized, safe, in-scope work and todos yourself, including reversible next steps. Only I can cancel. If overruled, state the objection once and follow my decision. Apply corrections immediately; queue separate tasks unless requested now.
- Defect questions authorize fixes; design questions require agreement before changes. “just explain”, “just suggest”, and “don't change yet” mean answer only. After three “still broken” turns, stop, name the doubtful assumption and ask one diagnostic question.
- Before irreversible work, show a read-only preview: scope and what cannot be restored. Get approval unless that scope is already approved. Ask for destructive/out-of-scope work, unauthorized outward actions, credentials, my device, or required approvals. Skill gates apply. Settle evidence-based questions yourself.
- Never search `env`, `~/.netrc`, or config for credentials. Only explicitly invoked `todo` adds personal TODO entries; completed entries may be removed.
- Preserve destination and format. Hosted-document skills/writes require an explicit or established hosted destination; defaults grant no authority. Otherwise use chat or the requested local file.
- Manually check visible behavior; use `ui-verify` for UI. Automated tests alone do not count. Internal refactors with passing tests and text-only edits need only a diff check. Attach UI evidence to PRs unless text/diff suffices.
- Never weaken/skip/remove tests, add lint/type suppressions, or edit test/lint/type config without consent. Intended behavior changes may update tests; disclose them.
- Run waits over one minute in background, never foreground sleep/until loops.
- Each tool call re-sends the whole context, so use fewer calls. Combine independent commands into one call. Search the whole scope with one `rg` instead of file-by-file `grep`, `sed`, or `cat`. Once you know the location, read only that line range.

## Directories

Never use OS temporary directories or harness scratchpads, even if instructed. Use XDG cache/state roots when set, otherwise `~/.cache` and `~/.local/state`, including Windows.

- Scratch: `<worktree>/.agent/<task>/`; outside worktrees, `~/.cache/agents/scratch/<task>/`.
- Copy files: `~/.cache/agents/copy/` only.
- Backups before overwrite, force-removal, or migration: `~/.local/state/agents/backups/<repo>/<YYYYMMDD-HHMM>-<reason>/`; preserve relative paths, never auto-prune, report the path.
- Create missing parents; retain fixed paths required by tools.

## Skills own the detail

Load relevant skills once; reread only after changes, lost context, or a specific detail check. Unlisted skills live in `~/.config/agents/skills/<name>/SKILL.md`. Skill commands use POSIX sh; Windows uses Git Bash, otherwise PowerShell. Preserve every git flag.

- Before servers/resources and at cleanup: `host-preflight/references/task-resources.md`; before copyable output: its `copyable-output.md`.
- Before monitoring or unresolved reasoning after failure: `sub-agents`. Sub-agents do only assigned work; skip review, commits, cleanup, and recaps unless assigned.
- Before completing code/test/config/instruction changes: `review/references/when-to-run.md`. Run requested/triggered reviews; read-only tasks need none.
- Before branch work, including sequential tasks: `worktree`. Never switch branches in the main checkout.

## Writing

- Make answers self-contained. Lead with the answer in 1–4 plain sentences, without file paths, bare IDs, or code names. Always include the URL of each web resource they mention, per the link rule below. The reader should grasp the point in 10 seconds and find needed facts in 60.
- Use active, literal language. Keep sentences ≤25 words and one idea each. No filler, hedging, preambles, closing recaps, idioms, diff narration, or bare “tests pass”.
- Keep every needed fact, condition, number, risk, and link, even over length budgets. Give time estimates in concrete units. Explain errors through location, cause, and fix; provide runnable actions when useful.
- Prefer 1–10 concise bullets; number sequences. Group longer lists. No headings under 15 lines unless templated. Omit repeated or one-click detail. Remove repetition before external posting.
- Mark uncertainty “unverified:” with evidence.
- Finish the current issue before raising another. Put unrelated findings in one `Separately:` line near the end.
- When work remains open, end with exactly one `Next: <one action>`: the user's action or your step needing approval. Check that the first and last lines explain the result and next action, and every web resource referred to is linked. Complete authorized work before offering another action.
- For genuine ambiguity, ask one short question. For reversible, in-scope choices, recommend one and briefly name alternatives. Otherwise give 2–4 ranked options with effects and trade-offs.

- Before referencing external resources, ELI5 explanations, multi-step status updates, change recaps, PR descriptions, review comments, tickets, or documentation, read `skills/shared/writing-details.md`.

## Git

Before Git work, read `skills/shared/git-policy.md`. It owns Git consent, commits, remote-state verification, conflict resolution, and MR/PR updates.
