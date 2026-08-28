---
name: split-task
description: >
  Decide whether to split the current task across parallel sub-agents: tasks that
  change 5+ non-doc files and divide into independent parts get split automatically;
  small, sequential, or context-sharing tasks run inline. Spawn mechanics, tiers,
  monitoring, and escalation live in the sub-agents skill. Use when starting any task
  that might split, or /split-task.
---

Split a task across sub-agents only when it saves cost or keeps the main session
free. The main session always owns the result: it re-validates whatever comes back
before declaring done. Every spawn follows the `sub-agents` skill.

## When to split

Split automatically — without being asked — when the task will change 5+ files
(excluding documentation) and divides into independent parts that each need
substantial reading or editing on their own: multi-file migrations, broad audits,
repetitive edits.

Run inline when the parts share most of their context, or the task is small or
sequential. Each spawned agent re-pays the shared context, so splitting a
medium-sized task costs MORE than doing it inline.

## How to split

- Give each part non-overlapping file ownership. This is the only rule this skill owns.
- Everything else — self-contained prompts, tier choice and the user's model/tool
  override, the shared prompt prefix for cache reuse, and re-validating results before
  declaring done — comes from the `sub-agents` skill. Do not restate it here.

## Not this skill

- Watching CI, logs, builds: the `sub-agents` skill's monitoring section.
- Handing a hard sub-problem or the whole task to a stronger tier: the `sub-agents`
  skill's escalation section.
- Several independent user-given tasks, one branch each: the `run-task-list` skill.
