---
name: sub-agents
description: >
  Use when spawning, monitoring, or escalating sub-agents. Owns model
  selection, prompts, handoffs, and result verification across harnesses.
---

Every spawn follows these rules. The spawning session owns verification and cleanup.

## Overrides (check first)

- A user-named model overrides the role's pin.
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
| `cheap` | Well-specified mechanical work: aggregation, formatting, extraction, counting, bulk replacement, factual lookup, watch-and-wait | haiku, low | gpt-5.6-luna, low |
| `explorer` | Locate usages and trace code paths; read-only | sonnet, medium | gpt-5.6-luna, xhigh |
| `worker` | Design, debugging, split implementation, review, research synthesis | opus, low | gpt-5.6-sol, low |
| `consult` | Main-session escalation only; read-only | fable, low | gpt-6-astra, low |

Claude Code forks (`subagent_type: "fork"`) inherit the parent model.
Use them only when a skill explicitly requests an inherited-context fork.
Escalate `cheap` or `explorer` work to `worker` when it needs judgement.
Without a sub-agent tool, work inline and identify any review that is not independent.

Compare total expected context, cache, output, and retry costs.
Do not retain an expensive role solely for its cache.

## Prompts

- Include the task, exact files or targets, and acceptance criteria. Do not rely on unpassed conversation context.
- Give independent reviewers only the context permitted by the `review` skill.
- Claude Code `cheap` skips rules files (`omitClaudeMd`). Include every rule it needs and name every output path.
- Request raw results: data, findings, and paths, not prose for the user.
- Sub-agents never spawn sub-agents. Claude Code role files deny `Agent`; Codex role files enforce this only through instructions.

## Prompt caching

Give parallel agents identical shared instruction prefixes, then the differing file lists or review items.
Continue an existing agent for related follow-up work when the harness supports it.

## Monitoring

For a command this session started, use the harness's completion notice or monitor tool when available.
For other targets (CI, deployments, remote logs), spawn a `cheap` background watcher.
It returns only the outcome and relevant details. The main session continues other work or ends its turn.
It never polls the same target itself.

Never watch an MR/PR or pipeline for success unless the user asks; `pr-unblock` counts as that request.
Otherwise, report the pipeline URL and stop: no watcher or polling.

## Escalate with `consult`

Only the main session may escalate. Sub-agents report blockers without escalating.
Use the current model stated in the system prompt; do not invent one.
If it already uses `consult` (fable, gpt-6-astra), continue inline or report the concrete blocker; no stronger model exists.

- **One hard sub-problem:** escalate after one failed attempt, a user-reported failure, or unresolved reasoning across files or systems.
  Spawn one `consult` with the problem, evidence, files, and points to settle.
  The task stays here, so no approval is needed. Re-validate the answer before acting.
  Escalate each sub-problem at most once.
- **Whole task on another model:** use a stronger model after failure or for subtle reasoning across systems.
  Use a cheaper role when the task permits it. Warn the user with the reason and get approval.
  Then give the full context to one `worker`, or `consult` when the current model is `worker`.
- On `cheap`, `explorer`, or `worker`, check that `consult` ran once before reporting blocked or attempting a second user-reported failure fix.

## After they return

- Re-validate every result before declaring done.
- Fix or redo failed results inline. Do not respawn for the same part more than once.
- Remove resources agents left: worktrees, servers, and ports. Keep artifacts only when the spawning skill requires them, such as review worktrees awaiting re-verification.
