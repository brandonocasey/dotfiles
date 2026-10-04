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
| `cheap` | Well-specified mechanical work: aggregation, formatting, extraction, counting, bulk replacement, factual lookup, watch-and-wait | haiku, low | gpt-6-luna, low |
| `explorer` | Locate usages and trace code paths; read-only | sonnet, medium | gpt-6-luna, medium |
| `worker` | Design, debugging, split implementation, research synthesis | claude-opus-5-5, medium | gpt-6.1-sol, low |
| `tester` | Run tests, lint, builds, and smoke checks; read-only | claude-sonnet-5-5, medium | gpt-6-luna, low |
| `manual-tester` | Exercise manual workflows; read-only | claude-opus-5-5, medium | gpt-6.1-sol, low |
| `consult` | Main-session escalation only; read-only | claude-fable-5-1, high | gpt-6-astra, max |
| `reviewer` | Independent review of a change; read-only | claude-opus-5-5, medium | gpt-6.1-sol, low |
| `hard-review` | Independent review when the user asks for a hard review; read-only | claude-opus-5-5, high | gpt-6.1-sol, high |

Claude Code forks (`subagent_type: "fork"`) inherit the parent model.
Use them only when a skill explicitly requests an inherited-context fork.
Escalate `cheap` or `explorer` work to `worker` when it needs judgement.
Without a sub-agent tool, work inline and identify any review that is not independent.

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

## Monitoring

For a command this session started, use the harness's completion notice or monitor tool when available.
For external targets, prefer a deterministic watcher such as `agent-watch`.
Start it once and use the harness's completion notice or monitor tool.
Use a `cheap` agent when the harness cannot monitor the process or interpretation is needed.
It runs the watcher once and reports the outcome and relevant details.
The main session never polls the same target while the watcher runs.

For a long run (workflow, build, or watcher), state an ETA in minutes at the start.
Report each phase change without a prompt.
Answer "status?" from the run's own log or journal.

Never watch an MR/PR or pipeline for success unless the user asks; `pr-unblock` counts as that request.
"When it merges, do X" also counts. Start one watcher with a long `--deadline-seconds`.
Run the queued action only when the watcher reports reason `merged`.
On any other result, such as `required_checks_passed`, a deadline, or a new head SHA, report it to the user.
`agent-watch` takes GitHub `OWNER/REPO#PR@SHA` and GitLab `GROUP[/SUBGROUP...]/PROJECT!IID@SHA` targets. For other platforms, say the watch is unsupported.
The queued action keeps its consent rules.
Otherwise, report the pipeline URL and stop: no watcher or polling.

## Escalate with `consult`

Only the main session may escalate. Sub-agents report blockers without escalating.
Use the current model stated in the system prompt; do not invent one.
Request a fresh independent assessment when it can resolve a specific blocker,
even if the consultant uses the same model. Same-model consultation is exceptional: a
failed attempt must leave a concrete question that fresh reasoning can settle.

- **One hard sub-problem:** escalate when a failed attempt leaves a specific unresolved question that needs independent reasoning. Correct routine command, syntax, and setup errors inline.
  Spawn one `consult` with the problem, evidence, files, and points to settle.
  The task stays here, so no approval is needed. Re-validate the answer before acting.
  Escalate each sub-problem at most once.
- **Whole task on another model:** use a stronger model after failure or for subtle reasoning across systems.
  Use a cheaper role when the task permits it. Warn the user with the reason and get approval.
  Then give the full context to one `worker`, or `consult` when the current model is `worker`.
- Before reporting blocked, use `consult` when the unresolved question meets the
  escalation condition above and the role is available, including the same-model case. Missing credentials, permissions, or user decisions do not require a consultant.

## After they return

- Re-validate every result before declaring done.
- Fix or redo failed results inline. Do not respawn for the same part more than once.
- Stop task-owned servers and processes agents left. Remove disposable artifacts.
  Follow `worktree` for retained open-PR worktrees and preservation checks; keep
  requested deliverables and evidence awaiting re-verification.
