---
name: sub-agents
description: >
  Use when spawning, monitoring, or escalating sub-agents. Owns model
  selection, prompts, handoffs, and result verification across harnesses.
---

Every spawn follows these rules. The spawning session owns verification and cleanup.

## Overrides (check first)

- A user-named model overrides the role's pin. Keep the role that fits the work; override only its model and effort.
- Read effort shorthand: `lo`/`low` low, `med`/`medium` medium, `hi`/`high` high, `xhigh`/`x high` xhigh, `max` max.
- Use a user-named custom harness agent. Check the loaded roster; ask if the name is unknown.
- Use a user-requested external tool or agent instead of a sub-agent. Verify its output before acting.

## Roles

Name a role below for every spawn unless the user names another agent.
Claude Code reads `~/.config/agents/agents/<role>.md`; Codex reads
`~/.codex/agents/<role>.toml`. Links for another harness do not prove support.
Check its loaded roster, effective model, thinking setting, and tools before spawning.
If the role is unavailable or incompatible, work inline and report the limitation.

Unless an override applies, keep the role's model and effort pins.
Never use a generic agent (`general-purpose`, `claude`, `default`) for work a role covers.
Omitting the role bypasses its pin: Claude Code inherits the parent model; Codex uses `default_subagent_model`.

| Role | Work | Claude Code | Codex |
| --- | --- | --- | --- |
| `cheap` | Named command execution, aggregation, formatting, extraction, counting, bulk replacement, factual lookup, watch-and-wait | haiku, low | gpt-6-luna, low |
| `explorer` | Locate usages and trace code paths; read-only | sonnet, medium | gpt-6-luna, medium |
| `worker` | Design, debugging, split implementation, research synthesis | claude-opus-5-5, medium | gpt-6.1-sol, low |
| `tester` | Select relevant tests, inspect failures, and validate evidence; read-only | claude-sonnet-5-5, medium | gpt-6-luna, low |
| `manual-tester` | Exercise manual workflows; read-only | claude-sonnet-5-5, medium | gpt-6.1-sol, low |
| `consult` | Main-session escalation only; read-only | claude-fable-5-1, high | gpt-6-astra, max |
| `reviewer` | Independent review of a change; read-only | claude-sonnet-5-5, medium | gpt-6.1-sol, low |
| `hard-review` | Independent review when the user asks for a hard review; read-only | claude-opus-5-5, high | gpt-6.1-sol, high |

Claude Code forks (`subagent_type: "fork"`) inherit the parent model.
Use them only when a skill explicitly requests an inherited-context fork.
Escalate `cheap` or `explorer` work to `worker` when it needs judgement.
Without a sub-agent tool, work inline and identify any review that is not independent.

For delegated named commands with explicit pass/fail criteria, use `cheap` and
request the exit status and bounded output. This includes executing a named test,
lint, or build command. Use `tester` when choosing checks or interpreting failures
requires judgment; use `worker` for diagnosis and fixes. Independent review keeps
its reviewer role. An explicit user role/model still wins. Do trivial commands
inline when spawning costs more; this routing does not require extra agents.

Compare total expected context, cache, output, and retry costs.
Do not retain an expensive role solely for its cache.

## Prompts

- Include the task, exact files or targets, and acceptance criteria. Do not rely on unpassed conversation context.
- Use fresh context for independent tasks. Pass only required evidence; inherit the full conversation only when the assignment needs it.
- Give independent reviewers only the context permitted by the `review` skill.
- For any role configured with `omitClaudeMd: true`, include the applicable repository constraints, required checks, and allowed output paths in its prompt. Pass only what the assignment needs.
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
