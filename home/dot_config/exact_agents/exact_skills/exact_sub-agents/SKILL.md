---
name: sub-agents
description: "Select, prompt, monitor, and verify sub-agents across Claude and Codex."
---

Before selecting or spawning any agent, read the global [Git policy](../shared/git-policy.md) when the assignment includes Git work. Every spawn follows these rules. The spawning session owns verification and cleanup.

Before choosing a role, model, or effort, read [roles.md](references/roles.md). It owns overrides, role pins, routing, compatibility checks, and escalation between roles.

## Prompts

- Include the task, owned files or targets, acceptance criteria, necessary evidence, and required checks. Do not rely on unpassed context.
- Spawn independent tasks without conversation history. In Codex, explicitly set `fork_turns="none"`; its omission can inherit the full conversation. Use a Claude named role rather than a conversation fork. Inherit history only when the assignment requires it.
- Give independent reviewers only the context permitted by the `review` skill.
- For roles with `omitClaudeMd: true`, include applicable repository constraints, required checks, allowed output paths, and any relevant global consent, destination, resource, or test protections absent from the role. Pass only what the assignment needs; do not paste the global rules or transcript.
- Request raw results: data, findings, and paths, not prose for the user.
- Sub-agents never spawn sub-agents. Claude Code role files deny `Agent`; Codex role files enforce this only through instructions.

## Prompt caching

Give parallel agents identical shared instruction prefixes, then the differing file lists or review items.
Continue an existing agent for related follow-up work when the harness supports it.

## Conditional procedures

- Before monitoring a command or external target, read [monitoring.md](references/monitoring.md).
- After a failed attempt leaves unresolved reasoning, read [escalation.md](references/escalation.md) before escalating or reporting blocked.
- Sub-agents report blockers to the parent; they never escalate.

## After they return

- Re-validate every result before declaring done.
- Fix or redo failed results inline. Do not respawn for the same part more than once.
- Stop task-owned servers and processes agents left. Remove disposable artifacts.
  Follow `worktree` for retained open-PR worktrees and preservation checks; keep
  requested deliverables and evidence awaiting re-verification.
