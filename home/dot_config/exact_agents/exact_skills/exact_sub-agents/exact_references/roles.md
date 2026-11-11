# Role selection

## Overrides (check first)

- A user-named model overrides the role's pin. Keep the role that fits the work; override only its model and effort.
- Read effort shorthand: `lo`/`low` low, `med`/`medium` medium, `hi`/`high` high, `xhigh`/`x high` xhigh, `max` max.
- Use a user-named custom harness agent. Check the loaded roster; ask if the name is unknown.
- Use a user-requested external tool or agent instead of a sub-agent. Verify its output before acting.

## Roles

Name a role below for every spawn unless the user names another agent.
Claude Code reads `~/.config/agents/agents/<role>.md`; Codex reads
`~/.codex/agents/<role>.toml`. A link or copy of these files in another harness does not prove it supports them.
Check its loaded roster, effective model, thinking setting, and tools before spawning.
If the role is unavailable or incompatible, work inline and report the limitation.

Unless an override applies, keep the role's model and effort pins.
Never use a generic agent (`general-purpose`, `claude`, `default`) for work a role covers.
Omitting the role bypasses its pin: Claude Code uses `CLAUDE_CODE_SUBAGENT_MODEL` (Sonnet), or inherits the parent model when that is unset; Codex uses `default_subagent_model`.
Name Fable 5.2 as `claude-fable-5-2[1m]` in a role's `model:` or `CLAUDE_CODE_SUBAGENT_MODEL`. Without `[1m]` it gets a 200k window on Claude Code before 2.1.321; the Agent tool `model` field takes aliases only, and `fable` there means 5.1.
Workflow `agent()` calls follow [workflows.md](workflows.md#agents).

| Role | Work | Claude Code | Codex |
| --- | --- | --- | --- |
| `cheap` | Named command execution, aggregation, formatting, extraction, counting, bulk replacement, factual lookup, watch-and-wait | claude-haiku-5-5, medium; trial: matched `xhigh` on 20 of 20 tasks, 40% faster | gpt-6-luna, xhigh |
| `explorer` | Locate usages and trace code paths; read-only | claude-haiku-5-5, medium; probe: matched Sonnet on usage lists and call traces; escalate to `worker` for judgement | gpt-6-luna, xhigh |
| `worker` | Design, debugging, implementation, orchestrated parts, research synthesis | claude-sonnet-5-5, high; default sonnet. Pass `model: opus` only for a design decision with no written plan, or a root-cause hunt after a sonnet worker failed once. Never for review fixes, finishing a PR, CI edits, or commit splitting | gpt-6.1-sol, high |
| `tester` | Run checks, manual cases, and UX checks; inspect failures and validate evidence; the `review` skill runs it with every review; changes no tracked files | claude-haiku-5-5, high; probes: on a 3-file Node change both models found 6 of 6 planted bugs; on a localized focus-return bug checked in a browser both found it in 2 of 2 runs; Haiku used about 1.3–2x the tokens | gpt-6.1-sol, high |
| `consult` | Main-session escalation, design critique, and open-question picks only; read-only | claude-opus-5-5, xhigh | gpt-6-astra, xhigh |
| `reviewer` | Independent adversarial review of a change; the `review` skill runs it for every review; read-only | claude-opus-5-5, xhigh; trials: on 27 changes `xhigh` found 20 of 31 known high/medium bugs and `high` 17, at $2.11 vs $1.13 per review; the `review` skill passes `model: haiku` for `low` risk tiers, and `model: sonnet` for fresh fix checks; both keep `xhigh` | gpt-6-astra, xhigh |
| `writing-reviewer` | Check the public text of a change (docs, code comments, commit messages, MR/PR title and description) against the writing rules; the `review` skill starts it with the `tester` in the first full review; read-only | claude-haiku-5-5, xhigh; Haiku's token price is 1/20 of Sonnet's; not yet trialed on writing checks | gpt-6-luna, xhigh |

Routing:

- Use `cheap` for named commands with explicit pass/fail criteria (a named test, lint, or build run; request exit status and bounded output) and to find one named file, definition, string, or config value; tell it not to edit.
- Use `cheap` for first-pass failure triage: it runs the named check and returns failing test names, error messages, and `file:line`. Diagnosis stays with `worker`. Probe: Haiku matched Sonnet on log triage.
- Use `explorer` to list usages, trace calls, or map affected files; before editing from its list, confirm with one broader `rg`.
- Main-session cost is per turn, so delegate when it replaces three or more turns: GitLab, Jira (`jira-api`), Jenkins, or Slack fetches to `cheap`; chained reads to understand code you will not edit, where each read depends on the last, to `explorer`. Claude Code `cheap` has read-only Slack tools; after the user consents to private search, tell it that private search is allowed.
- Use `tester` for manual or UX checks, doc reader passes, and when choosing checks or interpreting failures needs judgment; `worker` for diagnosis and fixes. Escalate `cheap` or `explorer` work to `worker` when it needs judgement.
- Independent review keeps its reviewer role. Do trivial commands inline when spawning costs more.
- Verify the key claims of any `haiku` run before acting on them.
- Without a sub-agent tool, work inline and identify any review that is not independent.
- Choose by total expected context, output, and retry cost, not cache reuse alone.
