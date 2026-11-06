# Auto-title cost probe: lean `claude -p` vs `--bare` vs plain `claude -p`

- Date: 2026-10-13  Sessions: 1aba7734  Raw data: none

## Question
Cost and latency of generating a session title with Haiku via `claude --bare`, a lean non-bare `claude -p` call, and a plain `claude -p` call.

## Setup
Pre-test cost estimate from third-party Haiku 5.5 pricing pages. Then real `claude -p` calls on a title prompt, one each: `--bare` (two versions), a lean non-bare call (short system prompt, no tools, no settings, no MCP), the lean call with CLAUDE.md files turned off, and a plain `claude -p`. Costs are as reported by Claude Code.

## Results
| Arm | Start tokens | Output tokens | Cost | Time | Outcome |
|---|---|---|---|---|---|
| `--bare` (both versions) | n/a | n/a | n/a | 0.03 s | "Not logged in" (needs an API key; the account uses a subscription login) |
| Lean non-bare | 620 | 112 | $0.00018 (first call) | 1.2 s | title "Fix Login Timeout Bug in Auth Service" |
| Lean, CLAUDE.md off | n/a | 13 | $0.000013 (cached) | 0.9 s | title returned |
| Plain `claude -p` | 210,575 | 3,753 | $0.0098 | 28.8 s | acted as a full agent: read code in three repos, no edits |

- Pre-test estimates: about $0.00006 per title for a lean `--bare` call (about 500 tokens in, 20 out; about $0.05 a month at 30 sessions a day); plain `claude -p` about $0.003 per title (about 25,000 tokens in; about $2.70 a month).
- Measured lean cost: at most about $0.0002 per title, about $0.16 a month at 30 sessions a day.
- Real-session test of the hook: title "Database Version Migration Plan" in 1.8 s, saved the same way as `/rename`. Slash-command prompts, later prompts and sessions that already had a name were skipped.

## Validity
- Single calls, not repeated.
- Plain-call estimate (about 25,000 tokens) vs measured 210,575.
- Review found 1 bug: the hook replaced names set with `claude -n`, because the session file does not exist when the hook runs. Fixed by checking the title passed in the hook input; a session started with `-n 'my chosen name'` then kept its name.
- `CLAUDE_CODE_SESSION_ATTENDED` is 0 for scripted runs and 1 for interactive; checked in hook runs in both modes.
- On a subscription, these calls count against usage limits instead of costing dollars.

## Decision
A UserPromptSubmit hook sets `sessionTitle` from a Haiku summary of the first prompt, using the lean non-bare call. Scripted `claude -p` runs get no title.

## Commits
- `0f5e9423 dx(claude): name sessions from the first prompt`
- `a23c3518 dx(claude): retitle sessions after /clear`
- `5d67fd3a dx(claude): give auto-titles specific, verb-first names`
- `5d77f1f9 feat(claude): name sessions from the built-in title`
- `5c1a0fc3 feat(claude): title tmux sessions via background haiku`
- `af92610f fix(claude): skip auto-title when haiku call hits limit`
- `85bcb5ba dx(claude): use readable session titles`
- `c615f1e0 fix(claude): skip auto-title on limit-reset nudge`
- `468dd076 feat(claude): start session names with the session's port`
- `d82235b3 fix(claude): drop the carried-over name on /clear`
- `e13918c7 feat(claude): name sessions by branch and part`
- `24756ce6 fix(claude): fit branch names beside the port`
- `05cc1ad4 fix(claude): rename only on a move to another branch`
- `0cc5217a fix(claude): let /rename beat a pending branch`
- `b016cc17 fix(claude): keep headless runs out of session naming`
