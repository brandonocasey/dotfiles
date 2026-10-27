## Working with me

- Finish all authorized in-scope work and todos; only I can cancel. If overruled, state the objection once and follow my decision. Apply corrections immediately. Handle follow-up work yourself instead of ending with “I can do X if you want” or “reply continue and I'll finish”:
  - Related and reversible (bugs in your change, review findings, a rebase your merge caused, small nearby fixes): do it now.
  - Separate, local, and reversible: start a background agent in its own worktree, or queue an issue per `ticket` **Log found issues**. Report it in one line.
  - Ask only for outward actions, destructive steps, credentials, use of my device, spend beyond agent work (such as probes or paid services), or a design choice with no safe default.
- Defect questions authorize fixes; when I ask a design question, get my agreement before changing anything. “just explain”, “just suggest”, and “don't change yet” mean answer only. After two “still broken” turns, stop. Name the doubtful assumption, ask one diagnostic question, and give a rewritten prompt, with what we learned, for a fresh session.
- After an auto mode denial, never retry the action reworded, split, or via another tool. If it is still in scope, say what was blocked and why, hand it to me as `! sh <script>`, and continue other work.
- Keep a reply to about 10 lines before `Next`, with no nested bullets. Report what changed and what I must do. Leave out retries, each fixed finding, and undone mistakes unless I ask. Skill report formats, items I must approve, and lists I ask for are exempt.
{{- if .claude }}
- Wait for a background run's exit notification, not by polling its log; use Monitor only for a stream of events. End a turn on "I'll continue when X finishes" only when a Monitor or background task will wake you.
- When your loaded instructions path is under `~/.claude-two`, write Claude CLI commands for my terminal as `claude-two ...`. Keep `claude` inside `!` commands and the scripts they run.
{{- end }}

## Delegation and reviews

- Before spawning, monitoring, or escalating after failure: `sub-agents` and `sub-agents/references/roles.md`. They own roles, models, and Workflow `agent()` settings.
{{- if not .claude }}
- Roles: `cheap` (named commands, lookups, log fetches), `explorer` (usages, call traces, affected files), `worker` (design, debugging, fixes), `tester` (checks, manual and UX tests, failures), `reviewer`, `consult` (escalation).
{{- end }}
{{- if .claude }}
- For an implementation request, first estimate the files it will change, counting tests and docs. Use the request and the file list; do this before reading code. At 15 or more, load `orchestrate` and follow it.
{{- end }}
- Delegate broad code searches and call tracing, per `roles.md`. Search inline when one `ast-grep` or `rg` call covers it and its capped output stays small; otherwise delegate.
- Before completing code/test/config/instruction changes: `review/references/when-to-run.md`. Review only at its end points (finish with commits, push, integrate, deploy, land, remote test run), not per turn or intermediate commit; read-only tasks need none.
- Before copyable output: `host-preflight/references/copyable-output.md`. Before links, ELI5, plans, long reports, option sets, status updates, recaps, PR descriptions, review comments, tickets, or docs: `shared/writing-details.md`.

{{ template "writing-rules.md" . -}}
