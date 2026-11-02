# Handoff to a background Sonnet session

## Handoff (main session)

Skip this section when this file was appended to your system prompt: you are
the orchestrator, so run the stages below.

1. Create a fresh directory with `mktemp -d <scratch>/handoff-XXXXXX` and use its printed path as `<dir>` below. Write the full request, constraints, and consents to `<dir>/request.md`.
2. Start with Bash in the background, from the worktree:
   `AGENT_HANDOFF=1 CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0 claude -p --model sonnet --append-system-prompt-file ~/.config/agents/skills/orchestrate/references/handoff.md --output-format json < <dir>/request.md > <dir>/orchestrator.json 2> <dir>/orchestrator.err`
   The request goes on stdin: a positional prompt that starts with `-` fails as an unknown option. Without the ceiling setting, print mode stops background sub-agents, such as a reviewer, 10 minutes after the orchestrator's last turn.
3. Record the starting commit (`git rev-parse HEAD`), then wait for the exit notification.
4. Verify: run the checks, read `git diff --stat` and `jq -r .result <dir>/orchestrator.json`, and confirm the orchestrator's `review-fix` covers the change: `agt review status --range <start>..HEAD` reports `reviewed: true` and an empty `unreviewed_commits`. The range catches commits that another session already pushed to the default branch. Run another review only when it does not or your checks fail. Report its open questions to the user.

## Stages (orchestrator)

1. **Implement.** One `worker` on its sonnet pin. It writes `decisions.md` per
   `sub-agents`. Check and commit.
2. **QA.** A fresh `tester` on the committed work, given the acceptance criteria
   as `Expected:`; record cases with `agt qa`.
3. **QA fixes.** Per **Prompt caching** in `sub-agents`, with `decisions.md`.
   Stop after 2 rounds, or sooner per `sub-agents`
   [escalation.md](~/.config/agents/skills/sub-agents/references/escalation.md), and report.
4. **Review.** Run `review-fix` and follow every step: its tester, its reviewer,
   and its `agt review` records through `agt review run end`. The main session
   reviews again when the store shows no review. Delegate its fixes as in stage 3.
5. **Docs.** Only when user-facing behavior, CLI, config, setup, or a public API
   changed: a fresh `worker` following `write-docs`, given the diff and
   `decisions.md`. For new or changed tutorials and how-tos, run the reader pass
   from `write-docs` yourself, since the worker cannot spawn agents, and send its
   findings back to the docs worker. Then `review-fix` on the docs commits, as
   in stage 4.
6. **Report.** Final report: commits, checks, the `review-fix` result with its
   reviewed head, the `reviewed` and `unreviewed_commits` fields of
   `agt review status`, and every open question.
