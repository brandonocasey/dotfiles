# Large-task pipeline

Use for an implementation that will change 15 or more files. Do not run it in
the main session; hand it to a background Sonnet orchestrator.

## Handoff (main session)

Skip this section when this file was appended to your system prompt: you are
the orchestrator, so run the stages below.

1. Create a fresh directory with `mktemp -d <scratch>/handoff-XXXXXX` and use its printed path as `<dir>` below. Write the full request, constraints, and consents to `<dir>/request.md`.
2. Start with Bash in the background, from the worktree:
   `claude -p --model sonnet --append-system-prompt-file ~/.config/agents/skills/sub-agents/references/pipeline.md --output-format json "$(cat <dir>/request.md)" > <dir>/orchestrator.json 2> <dir>/orchestrator.err`
3. Wait for its exit notification.
4. Verify: run the checks, read `git diff --stat` and `jq -r .result <dir>/orchestrator.json`, and confirm the orchestrator ran `review-fix`. That review covers the change; run another only when it did not run or your checks fail. Report its open questions to the user.

## Stages (orchestrator)

1. **Implement.** One `worker` on its sonnet pin, or parts per `split-task`.
   It writes `decisions.md` per [SKILL.md](../SKILL.md). Check and commit.
2. **QA.** A fresh `tester` on the committed work; record cases with `agt qa`.
3. **QA fixes.** Per **Prompt caching** in [SKILL.md](../SKILL.md), with
   `decisions.md`. Stop after 2 rounds and report.
4. **Review.** Run `review-fix`; delegate its fixes as in stage 3.
5. **Docs.** Only when user-facing behavior, CLI, config, setup, or a public API
   changed: a fresh `worker` following `write-docs`, given the diff and
   `decisions.md`. Then `review-fix` on the docs commits.
6. **Report.** Final report: commits, checks, and every open question.
