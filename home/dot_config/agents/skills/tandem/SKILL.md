---
disable-model-invocation: true
name: tandem
description: >
  Alias for run-task-list. Use for /tandem and tandem-ship or tandem-land
  requests to run a task list in parallel.
---

Read [run-task-list](../run-task-list/SKILL.md), resolved relative to this file,
and follow it. It owns task selection, delegation, review, and delivery.

Preserve the user's tasks, arguments, model choices, and split choices.
Treat `tandem-ship` as `run-task-list ship` and `tandem-land` as
`run-task-list land`; `/tandem ship` and `/tandem land` select the same modes.
Keep this alias's worktree naming: `.worktrees/tandem-<slug>` with branch
`<type>/<slug>`. With no end mode, leave the results local and committed.
