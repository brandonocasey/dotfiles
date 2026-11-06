# AGENTS.md without CLAUDE.md probe

- Date: 2026-10-15  Sessions: f6d3457a (context); probe sessions 7ac47f86 and 84e915cf  Raw data: the two probe transcripts survive as Claude project data; scratch dir `~/.cache/agents/scratch/agentsmd-probe` deleted, no results file

## Question
Whether Claude Code 2.1.296 loads a repo `AGENTS.md` when the repo has no `CLAUDE.md`, in a repo under `$TMPDIR` vs under `$HOME`, with and without a one-line `CLAUDE.md` (`@AGENTS.md`).

## Setup
Codeword probe. A repo with an `AGENTS.md` that holds the codeword "CANARYWORD". Prompt: "What is the project codeword from your loaded project instructions? Reply with only the codeword, or NONE if you have none. Do not read files." Two locations, `$TMPDIR` and under `$HOME`, run with `CLAUDE_CONFIG_DIR=~/.claude-two`. 1 run per arm, scored by the reply.

## Results
| Arm | Reply |
|---|---|
| `$TMPDIR` repo, bare `AGENTS.md` | CANARYWORD |
| Under `$HOME`, bare `AGENTS.md` (session 7ac47f86) | NONE |
| Under `$HOME`, `AGENTS.md` plus one-line `CLAUDE.md` `@AGENTS.md` (session 84e915cf) | CANARYWORD |

- Explanation recorded: Claude Code reads `AGENTS.md` only when no `CLAUDE.md` exists in the current folder or any parent folder (https://code.claude.com/docs/en/memory#agents-md). `~/.claude/CLAUDE.md` is a symlink to the global rules; with `CLAUDE_CONFIG_DIR` set to `~/.claude-two` it counts as a parent `CLAUDE.md` for every repo under `$HOME`.

## Validity
- One run per arm.
- The first probe ran outside `$HOME`, so it did not exercise the parent-file effect.
- The alternative `instructionFiles: "claude-md-and-agents-md"` for the built-in AGENTS.md plugin was not tested.
- Behavior with other Claude Code versions (older than 2.1.277) or parent `CLAUDE.md` files on other machines was not tested.

## Decision
Keep a one-line `CLAUDE.md` (`@AGENTS.md`) in each repo and package that has an `AGENTS.md`, with a README note in a shared conventions repo explaining why. Applied to four work repos.

## Commits
- None (project-repo changes only; no dotfiles commit).
