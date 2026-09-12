---
name: delegate
description: >
  Route delegation requests, background monitoring, and whole-task handoffs.
  For splitting one implementation task, use split-task.
---

Read only the route needed for the task. Resolve these paths relative to this file:

- Splitting one task: [split-task](../split-task/SKILL.md) owns the threshold and
  file ownership rules.
- Monitoring, model choice, or a whole-task handoff:
  [sub-agents](../sub-agents/SKILL.md) owns authorization, tier selection,
  prompts, monitoring, escalation, and result verification.
- Running a user-given task list: [run-task-list](../run-task-list/SKILL.md).

Every spawn follows `sub-agents`; this router adds no authorization.
