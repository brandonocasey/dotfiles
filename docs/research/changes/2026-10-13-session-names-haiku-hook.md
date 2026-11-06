# Session names from the first prompt via a Haiku hook

- Status (2026-11-06): current in part, reworked. `home/dot_claude/hooks/executable_auto-title.sh` still asks Haiku (`claude -p --model haiku`) in the background for a title on the first prompt, but it is now a verb-first plain-words title with the port in front, and branch and "Part N" naming sits on top of it (see the 2026-11-06 doc). Scripted `claude -p` runs are skipped.
- Topic: Hooks
- Related: [Session titles: port, branch and part](2026-11-06-session-titles-port-branch.md), [Auto-title cost probe](../ab-tests/2026-10-13-auto-title-cost.md)

## Change
A UserPromptSubmit hook sets `sessionTitle` from a short Haiku summary of the first prompt. The first design used `claude --bare`. `--bare` needs an API key (account login in use), so a lean non-bare call of 620 tokens is used instead. Scripted `claude -p` runs get no title.

## History
- 2026-10-13 — session 1aba7734, user: "can we create a claude mod to automatically /rename sessions?", then "estimate actual cost for 2" and "can you verify the starting context of --bare?".
- 2026-10-13 — `0f5e9423 dx(claude): name sessions from the first prompt`: new `auto-title.sh` plus a settings-template hook entry. The header says "Asks Haiku for a short title through a minimal headless call (~620 tokens)"; the prompt asks for a 3-6 word title; sessions with an existing title and slash commands are skipped.
- 2026-10-14 — session 27c2f151. `a23c3518 dx(claude): retitle sessions after /clear`: replaces a carried-over auto title; user-set names stay.
- 2026-10-15 — `5d67fd3a dx(claude): give auto-titles specific, verb-first names`: a stricter title prompt (verb first, keep ticket IDs and file names, no filler words, examples).
- 2026-10-16 — `5d77f1f9 feat(claude): name sessions from the built-in title`: switched to Claude Code's own generated title (an `ai-title` entry written after the first prompt), calling Haiku only after `/clear`, when Claude makes none. The name then appears from the second prompt.
- 2026-10-16 — `5c1a0fc3 feat(claude): title tmux sessions via background haiku`: Haiku names the session right after the first prompt, in the background; `/rename` reaches tmux through the status line; exiting restores the old name. This put the Haiku call back as the main path.
- 2026-10-16 — `af92610f fix(claude): skip auto-title when haiku call hits limit`: a failed call (usage limit, auth, timeout) printed its error as the answer; output from a non-zero exit or a limit message is now dropped.
- 2026-10-29 — `85bcb5ba dx(claude): use readable session titles`: filename-style slugs became plain words in sentence case under 50 characters (e.g. "Fix stop-hook loop"); hand-backs from another session are skipped.
- 2026-11-05 — `c615f1e0 fix(claude): skip auto-title on limit-reset nudge`: Claude's "Your claude.ai usage limit has reset" nudge is not a topic.
- 2026-11-06 — `468dd076 feat(claude): start session names with the session's port`, `d82235b3 fix(claude): drop the carried-over name on /clear`, `e13918c7 feat(claude): name sessions by branch and part` and later fixes; see the 2026-11-06 doc for each.

## Results
Measured: about $0.0002 per Haiku title at most, about $0.16 a month at 30 sessions a day ([cost probe](../ab-tests/2026-10-13-auto-title-cost.md)). The $0.00006 figure was the pre-test estimate. `--bare` was ruled out because it needs an API key. A real-session test passed and review found 1 bug, which was fixed. Problems seen later: a failed Haiku call wrote its error text as a title (`af92610f`), hand-backs and limit-reset nudges were titled as topics (`85bcb5ba`, `c615f1e0`), and slug-style titles were unreadable (`85bcb5ba`). The design swung to Claude's built-in title on 2026-10-16 and back to background Haiku the same day.

## Sources
- [eesel.ai, Claude Haiku 5.5 pricing](https://www.eesel.ai/blog/claude-haiku-5-5-pricing) — Haiku 5.5 price used to estimate per-title cost (about $0.00006 lean, $0.003 plain).
- [apidog, Claude Haiku 5.5 pricing](https://apidog.com/blog/claude-haiku-5-5-pricing/) — same.
- [letsdatascience, Haiku 5.5 price cut](https://letsdatascience.com/blog/claude-haiku-5-5-cut-prices-90-prompts-over-100k-pay-5x) — same.

## Evidence
Cited in the reply and flagged by the assistant as "from third-party sites, not Anthropic's own pricing page". The `sessionTitle` capability came from the app binary ("I saw the field in the app code"), not a doc. Session 1aba7734 (2026-10-13). Sessions behind `5d67fd3a`, `5d77f1f9`, `5c1a0fc3`, `af92610f`, `85bcb5ba` and `c615f1e0` were not identified.
