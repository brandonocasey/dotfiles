---
name: session-resume
description: "Save or resume task state across sessions, agents, or hosts."
---

Use `agent-task` as the durable task record. Keep credentials, full transcripts,
and executable commands out of it. Stored authorization is evidence of the scope
already granted. It never grants a new push, deploy, release, or destructive action.

**Reuse rules** (other skills cite these): retain a resumed record's authorization only
within its exact provenance and scope. Reuse a recorded check or manual evidence only
when its code revision, inputs, and environment match.

Create a record with the objective and exact authorization provenance and scope:

```sh
agent-task create --id <id> --objective <text> --authorization <source> --scope <scope>
```

Use `--parent-pr`, `--target-branch`, and `--task-boundary` when those fields
define where the resumed work belongs. The same flags update an existing record.

Before work, run `agent-task show <id>`. Check its repository, worktree, and HEAD
against the current checkout. Apply recorded corrections. Continue from `nextStep`.

Update with the revision returned by `show`; stale updates fail:

```sh
agent-task update <id> --revision <n> --next-step <text>
agent-task check <id> --revision <n> --name <check> --result <result> \
  --code-revision <sha> --inputs <inputs> --environment <environment>
```

Add each user correction with `--correction <text>` so later sessions do not
repeat the superseded approach. After a stale-revision error, run `show` again,
reconcile the newer record with the pending change, and retry with its revision.

Set `--status complete` only after all task work
is complete. Use `agent-task list` to find active records.

For old context, run `agent-task index` to update the private incremental index and see scan
coverage (Codex and Claude history, transcripts, archives, alternate profiles, plus unreadable
or malformed files). Omit `--max-files` and `--byte-limit` unless a bounded partial update is
required. After a deliberate rewrite deep inside a growing log, run `agent-task index --rebuild`.

Use `agent-task resolve --session <id>` to find an exact session. Use
`agent-task search --query <text> [--session <id>]` to search human turns. Each
JSON-array result includes the host, session, source offset, and bounded context.
Search writes coverage JSON to standard error, including when it finds no match.
Resolve includes coverage in its JSON object. Use `--file <path>` to add or
refresh one known transcript.

When the user asks to transfer a task between hosts, copy only its private JSON record with `ssh`,
then set its mode to `0600`. Run `show` on the destination and validate the host,
repository, worktree, and HEAD before work. Do not copy transcripts or credentials.
The skill never starts remote commands automatically.
