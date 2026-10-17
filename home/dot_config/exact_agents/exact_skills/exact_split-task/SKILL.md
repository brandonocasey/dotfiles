---
name: split-task
description: "Assess independent implementation parts before multi-file work or requested task splitting."
---

Split a task across sub-agents only when it saves cost or keeps the main session
free. Spawn per `sub-agents`.

## When to split

Split automatically when the task will change 5+ files (excluding documentation)
and divides into independent parts that each need substantial reading or editing
on their own: multi-file migrations, broad audits, repetitive edits. Give each part
non-overlapping file ownership. Keep the split plan in a file, per the long-output
rule in [writing-details.md](../shared/writing-details.md).

Run inline when the parts share most of their context, or the task is small or
sequential. Each spawned agent re-pays the shared context, so splitting a
medium-sized task costs more than doing it inline.
