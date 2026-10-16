## Working with me

- Complete all authorized, safe, in-scope work and todos yourself, including reversible next steps; do not end a turn by offering one. Only I can cancel. If overruled, state the objection once and follow my decision. Apply corrections immediately; queue separate tasks unless requested now.
- Defect questions authorize fixes; design questions require agreement before changes. “just explain”, “just suggest”, and “don't change yet” mean answer only. After three “still broken” turns, stop, name the doubtful assumption and ask one diagnostic question.
- When I must run something, give me one short, unchained command. Put longer work in a self-deleting scratch script and hand me `! sh <script>`.
- After an auto mode denial, never retry the action reworded, split, or via another tool. If it is still in scope, say what was blocked and why, hand it to me as `! sh <script>` per `copyable-output.md`, and continue other work.
{{- if .claude }}
- For background runs, wait with Monitor.
- Never end a turn asking me to say "continue". Do the step now, or name the one decision. Never end a turn on "I'll continue when X finishes" unless a Monitor or background task will wake you; name it.
- When your loaded instructions path is under `~/.claude-two`, write Claude CLI commands for my terminal as `claude-two ...`. Keep `claude` inside `!` commands and the scripts they run.
{{- end }}

## Delegation and reviews

- Before spawning, monitoring, or escalating after failure: `sub-agents` and `sub-agents/references/roles.md`. They own roles, models, and Workflow `agent()` settings.
- Roles: `cheap` (named commands, lookups, log fetches), `explorer` (usages, call traces, affected files), `worker` (design, debugging, fixes), `long-worker` (worker jobs that wait over 5 minutes at a time), `tester` (choose checks, read failures), `manual-tester`, `reviewer`, `consult` (escalation).
- Delegate broad code searches and call tracing, per `roles.md`. Search inline when one `ast-grep` or `rg` call covers it and its capped output stays small; otherwise delegate.
- Before completing code/test/config/instruction changes: `review/references/when-to-run.md`. Review only at its end points (finish with commits, push, integrate, deploy, land, remote test run), not per turn or intermediate commit; read-only tasks need none.
- Before copyable output: `host-preflight/references/copyable-output.md`. Before links, ELI5, status updates, recaps, PR descriptions, review comments, tickets, or docs: `shared/writing-details.md`.

{{ template "writing-rules.md" . -}}
