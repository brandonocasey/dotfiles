---
name: session-resume
description: >
  Save and resume shared task state across agent sessions or hosts. Use when work
  must continue later, transfer between agents, or recover prior task context.
---

# Resume task state

Use `agent-task` as the durable task record. Keep credentials, full transcripts,
and executable commands out of it. Stored authorization is evidence of the scope
already granted. It never grants a new push, deploy, release, or destructive action.

Create a record with the objective and exact authorization provenance and scope:

```sh
agent-task create --id <id> --objective <text> --authorization <source> --scope <scope>
```

Use `--parent-pr`, `--target-branch`, and `--task-boundary` when those fields
define where the resumed work belongs. The same flags update an existing record.

Before work, run `agent-task show <id>`. Check its repository, worktree, and HEAD
against the current checkout. Apply recorded corrections. Continue from `nextStep`.
Use a completed check only when its code revision, inputs, and environment still
match. Follow the active workflow's review and approval rules.

Update with the revision returned by `show`; stale updates fail:

```sh
agent-task update <id> --revision <n> --next-step <text>
agent-task check <id> --revision <n> --name <check> --result <result> \
  --code-revision <sha> --inputs <inputs> --environment <environment>
```

Add each user correction with `--correction <text>` so later sessions do not
repeat the superseded approach. After a stale-revision error, run `show` again,
reconcile the newer record with the pending change, and retry with its revision.

Record material corrections and set `--status complete` only after all task work
is complete. Use `agent-task list` to find active records.

For old context, run `agent-task index` to update the private incremental index
and see scan coverage. It covers Codex and Claude history, active transcripts,
archives, and alternate Claude profiles. The coverage reports unreadable files,
malformed or oversized lines, removals, and optional scan limits. The default
indexes all discovered files. Use `--max-files` or `--byte-limit` only when a
bounded partial update is required. Omit those limits for a complete update.
The index assumes append-only session logs. It detects replacement, truncation,
same-size edits, and changes to the saved prefix or last 64 KiB during growth.
For a deliberate rewrite deeper inside a growing log, rebuild with
`agent-task index --rebuild`.

Use `agent-task resolve --session <id>` to find an exact session. Use
`agent-task search --query <text> [--session <id>]` to search human turns. Each
JSON-array result includes the host, session, source offset, and bounded context.
Search writes coverage JSON to standard error, including when it finds no match.
Resolve includes coverage in its JSON object. Use `--file <path>` to add or
refresh one known transcript.

To transfer a task between hosts, copy only its private JSON record with `ssh`,
then set its mode to `0600`. Run `show` on the destination and validate the host,
repository, worktree, and HEAD before work. Do not copy transcripts or credentials.
The skill never starts remote commands automatically.
