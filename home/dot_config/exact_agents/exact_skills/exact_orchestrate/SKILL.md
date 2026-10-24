---
name: orchestrate
description: "Run large implementation work as parallel parts, one worktree each, with per-part test and review and one integration pass. Rarely needed."
---

Do implementation work inline by default. Orchestrate only when the user asks,
or when the task divides into independent parts that each need substantial
reading or editing on their own (broad multi-file migrations, repetitive edits
across many files). Run inline when the parts share most of their context, or
the task is small or sequential: each part re-pays the shared context and gets
its own tester and reviewer.

The main session runs every stage; no agent orchestrates another. Spawn per
`sub-agents`. Each part moves through its stages on its own timeline: start a
part's next stage as soon as its current one returns, without waiting for the
other parts.

## Setup

1. Write the plan to a file, per the long-output rule in
   [writing-details.md](../shared/writing-details.md): parts, non-overlapping
   owned files, acceptance criteria, and scoped checks for each part.
2. Pick one base commit. Create one worktree per part yourself, per
   `worktree/SKILL.md`: `agt worktree create <task>-<n> --base <base> --prepare --background`.
   Collect each with `agt worktree prepare --wait` before spawning into it.

## Stages (per part, in its own worktree)

1. **Implement.** A background `worker` given its worktree path, owned files,
   and scoped checks. It writes `<scratch>/<task>/part-<n>/decisions.md` per
   `sub-agents`.
2. **Verify.** Check the diff covers the assignment and touches only owned
   files, the scoped checks pass, and `decisions.md` exists. Commit in the
   part's worktree.
3. **QA.** A fresh `tester` on the part's worktree; record cases with `agt qa`.
4. **QA fixes.** A `worker` per **Prompt caching** in `sub-agents`, with
   `decisions.md`. Stop after 2 rounds and report the part blocked.
5. **Review.** Run `review-fix` on the part's branch against `<base>`; delegate
   its fixes as in stage 4.

## Integrate (once all parts finish)

1. Merge the part branches into the task branch, per the Git policy's conflict
   rules.
2. Run the repository's required pre-commit checks and a fresh `tester` on the
   merged result, focused on behavior that spans parts. Fix as in stage 4.
3. Run `review-fix` on the merge resolutions and integration fixes only; each
   part's own commits were already reviewed.
4. **Docs.** Only when user-facing behavior, CLI, config, setup, or a public API
   changed: a fresh `worker` following `write-docs`, given the diff and every
   `decisions.md`. For new or changed tutorials and how-tos, run the reader pass
   from `write-docs` yourself and send its findings back to the docs worker.
   Then `review-fix` on the docs commits.
5. Remove the part worktrees per `worktree/SKILL.md`.
6. **Report.** Per part and for the integration: commits, checks, the
   `review-fix` result with its reviewed head, and every open question.
