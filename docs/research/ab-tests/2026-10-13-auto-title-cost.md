# Auto-title cost probe

- Date: 2026-10-13 (19:24-19:54 UTC)  Sessions: 1aba7734  Raw data: none.
- Related: [Session names from the first prompt via a Haiku hook](../changes/2026-10-13-session-names-haiku-hook.md), [Session titles by port, branch and part](../changes/2026-11-06-session-titles-port-branch.md)

## Question
What does a Haiku session-title hook cost, and will `claude --bare` work for it? The user asked "can we create a claude mod to automatically /rename sessions?" then "estimate actual cost for 2" (the Haiku summary option).

## Setup
Cost estimate from third-party Haiku 5.5 pricing pages, then real `claude -p` calls on a title prompt: `--bare` (two versions), a lean non-bare call (short system prompt, no tools, no settings, no MCP), the same with CLAUDE.md files turned off, and a plain `claude -p`. Costs are what Claude Code reported.

## Results
- Estimate before testing: about $0.00006 per title for a lean `--bare` call (about 500 tokens in, 20 out; about $0.05 a month at 30 sessions a day); plain `claude -p` about $0.003 per title (about 25,000 tokens in; about $2.70 a month).
- `--bare` (both versions): "Not logged in" in 0.03 s. It needs an API key; the account login is a subscription login.
- Lean non-bare call: starts at 620 tokens, 112 output tokens, $0.00018 for the first call, 1.2 s, title "Fix Login Timeout Bug in Auth Service". With CLAUDE.md files also turned off: 13 output tokens, $0.000013 cached, 0.9 s.
- Plain `claude -p`: 210,575 starting tokens, 3,753 output tokens, $0.0098, 28.8 s. It worked on the task like a full agent (read code in three repos, no edits). Never use a plain call for this.
- Measured lean cost: about $0.0002 per title at most, about $0.16 a month at 30 sessions a day. The assistant noted its $0.05 estimate was a bit low. On a subscription these calls count against usage limits instead of costing dollars.
- A real-session test passed: a session got the title "Database Version Migration Plan" in 1.8 s, saved the same way as `/rename`. Slash-command prompts, later prompts and sessions that already had a name were skipped.

## Validity
- Single calls, not repeated.
- The review found 1 real bug: the hook replaced names set with `claude -n`, because the session file does not exist yet when the hook runs. Fixed by checking the title Claude Code passes in the hook input; a session started with `-n 'my chosen name'` then kept its name.
- Scripted runs: the review noted `claude -p` jobs would also pay for a Haiku call. The user chose to skip them. The hook checks `CLAUDE_CODE_SESSION_ATTENDED` (0 for scripted runs, 1 for interactive), checked in hook runs in both modes.
- Unverified in the session: the "about 25,000 tokens" plain-call estimate before measuring; the later run measured 210,575.
- The $0.00006 figure quoted in the earlier version of this record was the pre-test estimate, not the measured cost.

## Decision
A UserPromptSubmit hook sets `sessionTitle` from a Haiku summary of the first prompt, using the lean non-bare call. Scripted `claude -p` runs get no title.

## History
- 2026-10-13 — Probe and build in 1aba7734.
- 2026-10-13 — `0f5e9423 dx(claude): name sessions from the first prompt`: new `auto-title.sh` and the hook entry in `claude-settings-modify.sh`.
- 2026-10-14 — `a23c3518 dx(claude): retitle sessions after /clear`.
- 2026-10-15 — `5d67fd3a dx(claude): give auto-titles specific, verb-first names`.
- 2026-10-16 — `5d77f1f9 feat(claude): name sessions from the built-in title`, `5c1a0fc3 feat(claude): title tmux sessions via background haiku` (Haiku names the session right after the first prompt in the background; `/rename` reaches tmux through the status line), `af92610f fix(claude): skip auto-title when haiku call hits limit`.
- 2026-10-29 — `85bcb5ba dx(claude): use readable session titles`.
- 2026-11-05 — `c615f1e0 fix(claude): skip auto-title on limit-reset nudge`.
- 2026-11-06 — `468dd076 feat(claude): start session names with the session's port`, `d82235b3 fix(claude): drop the carried-over name on /clear`, `e13918c7 feat(claude): name sessions by branch and part`, `24756ce6 fix(claude): fit branch names beside the port`, `05cc1ad4 fix(claude): rename only on a move to another branch`, `0cc5217a fix(claude): let /rename beat a pending branch`. Later commits also keep headless runs out of naming (`b016cc17 fix(claude): keep headless runs out of session naming`).
- Today: `home/dot_claude/hooks/executable_auto-title.sh` still runs `claude -p --model haiku` with `CLAUDE_CODE_DISABLE_CLAUDE_MDS=1` and `timeout 30`, and skips unattended runs; it also handles port and branch naming. Per-title cost was not re-measured.
