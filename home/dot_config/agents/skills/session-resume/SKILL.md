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

For old context, prefer `codex_tui` `read_thread` when available because it can
select a bounded thread. Otherwise use `agent-task search --query <text>` across
recent Claude and Codex history. Use `--file <path>` to read one selected session.
Search returns only user and assistant text. It returns at most 20 short matches
by default and reads at most the final 2 MB of each file.

To transfer a task between hosts, copy only its private JSON record with `ssh`,
then set its mode to `0600`. Run `show` on the destination and validate the host,
repository, worktree, and HEAD before work. Do not copy transcripts or credentials.
The skill never starts remote commands automatically.
