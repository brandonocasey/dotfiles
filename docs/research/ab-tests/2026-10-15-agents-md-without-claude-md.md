# AGENTS.md without CLAUDE.md probe

- Date: 2026-10-15  Sessions: f6d3457a (2026-10-14/15, web-player, work on hive, web-player and conventions repos); probe sessions 7ac47f86 and 84e915cf (2026-10-15)  Raw data: the probe scratch dir `~/.cache/agents/scratch/agentsmd-probe` is deleted (`test -e` fails). The two probe transcripts survive as Claude project data; no results file.
- Related: [Agent starting-context audit](2026-10-13-agent-starting-context.md) (instruction files are the largest start-up cost, which is why repo rules were being condensed)

## Question
Does Claude Code 2.1.296 load a repo `AGENTS.md` when the repo has no `CLAUDE.md`? The question came up while condensing repo rule files in f6d3457a (merge `AGENTS_PROJECT.md` into `AGENTS.md`, drop rules the global config already covers). The user's first request was to cut the repo `AGENTS.md` and move `AGENTS_PROJECT.md` into it.

## Setup
Codeword probe. A repo with an `AGENTS.md` that holds the codeword ("PELICAN") and no `CLAUDE.md`. The prompt asked: "What is the project codeword from your loaded project instructions? Reply with only the codeword, or NONE if you have none. Do not read files." Two locations: one in `$TMPDIR` and one under `$HOME`, run with `CLAUDE_CONFIG_DIR=~/.claude-two`.

## Results
- `$TMPDIR` repo, bare `AGENTS.md`: the codeword was returned. The session then removed every repo `CLAUDE.md`.
- Under `$HOME`, bare `AGENTS.md`: the answer was `NONE` (session 7ac47f86, 15:37 UTC).
- Under `$HOME` with a one-line `CLAUDE.md` (`@AGENTS.md`): the answer was `PELICAN-42` (session 84e915cf, 15:40 UTC).
- Reason given by the session: Claude Code reads `AGENTS.md` only when no `CLAUDE.md` exists in the current folder or any parent folder. The user file `~/.claude/CLAUDE.md` is a symlink to the global rules. With `CLAUDE_CONFIG_DIR` set to `~/.claude-two`, it counts as a parent `CLAUDE.md` for every repo under `$HOME`. The session cited https://code.claude.com/docs/en/memory#agents-md for the rule.
- Risk the session named: without the files, web-player and hive sessions on this machine would load no repo rules. Teammates with any parent `CLAUDE.md`, or with Claude Code older than 2.1.277, would also silently get none.

## Validity
- The first probe ran outside `$HOME`, so it missed the parent-file effect. An independent review of the hive and conventions changes raised the finding; the assistant re-ran the probe under `$HOME` and confirmed it.
- The deletions in all three repos had already been made when the finding came in. They were restored (the one-line `CLAUDE.md` files and the conventions README note).
- The review also named `instructionFiles: "claude-md-and-agents-md"` for the built-in AGENTS.md plugin as an alternative fix for this machine. The session marked it unverified and did not test it.
- Each probe is one run.

## Decision
Keep a one-line `CLAUDE.md` (`@AGENTS.md`) in each repo and package that has an `AGENTS.md`, and keep a README note in conventions explaining why. Applied to hive (including a new root file and `audio-experience-service`), web-analytics, conventions and web-player. A later correction in the session: the README now says the user's own `CLAUDE.md` does not block `AGENTS.md`, but a leftover `~/.claude/CLAUDE.md` does when `CLAUDE_CONFIG_DIR` is set. These were project-repo changes on branches (`dx/condense-agents-md` in web-player, `dx/web-analytics-agents-md` in hive, `docs/agents-personal-guide` in conventions), nothing pushed at the end of the session.

## History
- 2026-10-14 — Request: session f6d3457a started with the request to condense the repo `AGENTS.md` and fold in `AGENTS_PROJECT.md`.
- 2026-10-15 — First probe in `$TMPDIR` found `AGENTS.md` loaded, so the session removed every repo `CLAUDE.md`.
- 2026-10-15 — Review finding led to a second probe under `$HOME` (NONE, then PELICAN-42 with a one-line `CLAUDE.md`). The session restored the files and added the README note; web-player lint, build and unit tests passed (3420 passed, 0 failed) on the first draft.
- No dotfiles commit: searched `git log -S'CLAUDE.md' -- home`; hits were unrelated skill text. The dotfiles global rules do not mention this convention.
- Today: the web-player primary checkout has a `CLAUDE.md` containing `@AGENTS.md` and `@AGENTS_PROJECT.md` (that checkout may not be on the condense branch). The state of the other repos was not checked.
