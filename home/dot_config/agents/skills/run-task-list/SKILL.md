---
disable-model-invocation: true
name: run-task-list
description: >
  Run a user-given task list in parallel and review each result. Use for batch
  or tandem requests; explicit ship/land modes control delivery.
---

Run tasks in parallel and review every result. Follow `sub-agents` for delegation,
`review` for code review, and `commit` for commits.

## Modes and arguments

- **End mode:** `ship` / `run-task-list-ship` pushes branches and opens or updates MRs/PRs without watching CI.
  `land` / `run-task-list-land` merges locally to default and cleans up.
  Without either, leave branches local and committed.
  The selected mode authorizes that explicit-only workflow after review.
  Read [ship](../ship/SKILL.md) or [land](../land/SKILL.md) for the selected mode, then follow every step.
- **User splits:** follow the requested grouping, agent count, package split, and model choices instead of step 2's grouping.
  If parallel agents would share files, warn once with the concrete reason, then follow the user's decision.
- **User agents:** a named custom agent, model, or external tool overrides the role choice for that assignment.
  Check custom names against the loaded roster; ask before spawning an unknown agent.

## 1. Collect tasks

Take explicitly listed tasks or outcomes verbatim.
If asked to select from a source (TODO.md, plan file, issue tracker, Jira filter, earlier message), read it first.
For an issue tracker, read open issues with the remote's CLI: `gh`, `glab` (`GITLAB_HOST` for self-hosted), or `fj`.
Read comments only when the issue body points to them.
Choose independent tasks with separate files, checkable outcomes, and no user decisions needed mid-task.
Skip destructive, outward-facing, or vague tasks; report each skipped task and reason.
Never add to the source list. Report completions either way.
You may remove an item after its task passes step 3. Only the main session edits the source, never a task worktree.
If the source is tracked, commit the removal on that task's branch; otherwise edit the file in place.

Write one line of acceptance criteria per selected task.
Before spawning, ask only about unknown agent names or tasks without checkable outcomes.
State the selected tasks and plan in one short message, then proceed.

## 2. Split and spawn

- Follow user splits. Otherwise group tasks with overlapping files into one agent, which runs them sequentially.
  Give each other task its own agent.
- Code tasks use one worktree per agent, per `worktree`, with path `.worktrees/task-<slug>` and branch `<type>/<slug>`.
  An invoking alias, such as `tandem`, owns its naming override.
  Research, documentation lookups, and external checks need no worktree.
- Each prompt includes the task, acceptance criteria, worktree path, and its own `PORT` when running a server.
  Require edits only inside that worktree and disjoint file ownership between parallel agents.
  Request raw status: done / blocked / partial, changes, verification, and touched files.
- Use user-assigned agents or models; otherwise choose per `sub-agents`.
  Run groups in parallel and use completion notices rather than idle polling.

## 3. Adversarial review

For each returned task, the main session checks its acceptance criteria.
Treat completion without evidence as unverified.

- **Code:** run `review` on the worktree's diff under its own-work fix rules.
  Fix test and lint failures; do not dismiss them as pre-existing.
- **Non-code:** spawn one verifier to refute the result against its acceptance criteria.
  Uncertain means refuted. Fix or redo failures inline per `sub-agents`, then check the criteria again.

Never report completion without passing review or refutation against the acceptance criteria.

## 4. Close out

- Commit every worktree through `commit`; leave no task changes uncommitted.
- Follow the selected end-mode skill for branches whose assigned tasks all passed step 3.
  Keep blocked or partial branches local. Land eligible branches one at a time.
  Without an end mode, keep branches local.
- If the user asked for as many or all source items, select the next batch from items that no earlier batch of this run selected.
  Repeat steps 1-4. Stop when no eligible item is left or when a batch has no task that passes step 3.
- On completion, failure, cancellation, or blocked exit, stop servers, free ports, and close browser pages opened by the batch.
  Keep worktrees with commits or partial changes needed for recovery; remove empty worktrees.
- Report each task as done / blocked / partial / skipped, with one plain sentence and verification evidence.
  For code tasks, include branch and worktree paths. Include selections and skips when choosing from a list.
  End with external links under **Links** (tickets, MRs/PRs, CI) and one concrete next action.
  Without an end mode, suggest `ship <branch>`; after shipping, give MR/PR links; after landing, give the default-branch state.

For issue sources, list each issue that a landed or shipped task fully completes.
If the user asks whether any can be closed, list them and ask: "Close these N issues now?"
Close issues only on an explicit close request.
Use the same CLI as the source; on any other platform, stop before the close and report it.
Merge or change other tickets or MRs only when the user asks.
