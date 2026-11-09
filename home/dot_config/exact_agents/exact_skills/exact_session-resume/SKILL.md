---
name: session-resume
description: "Save or resume task state across sessions, agents, or hosts; pause work and its agents, then continue with fresh agents."
---

Use `agt task` as the durable task record. Keep credentials, full transcripts,
and executable commands out of it. Stored authorization is evidence of the scope
already granted. It never grants a new push, deploy, release, or destructive action.

**Reuse rules** (other skills cite these): retain a resumed record's authorization only
within its exact provenance and scope. Reuse a recorded check or manual evidence only
when its code revision, inputs, and environment match.

Create a record with the objective and exact authorization provenance and scope:

```sh
agt task create <id> --objective <text> --authorization <source> --scope <scope>
```

Use `--parent-pr`, `--target-branch`, and `--task-boundary` when those fields
define where the resumed work belongs. The same flags update an existing record.

Before work, run `agt task show <id>`. Check its repository, worktree, and HEAD
against the current checkout. Apply recorded corrections. Continue from `nextStep`.

Update with the revision returned by `show`; stale updates fail:

```sh
agt task update <id> --revision <n> --next-step <text>
agt task update <id> --revision <n> --check-name <check> --check-result <result> \
  --check-code-revision <sha> --check-inputs <inputs> --check-environment <environment>
```

Add each user correction with `--correction <text>` so later sessions do not
repeat the superseded approach. After a stale-revision error, run `show` again,
reconcile the newer record with the pending change, and retry with its revision.

Set `--status complete` only after all task work
is complete. Use `agt task list` to find active records.

## Pause and continue

Here `<keep>` is `${XDG_STATE_HOME:-~/.local/state}/agents/handoffs/<task>/`,
for the `<task>` whose `TODO.md` is in `agents/output/<task>/`. It stays out of
`agents/output`, which `agt cleanup` empties after 7 days unchanged. Remove it
with `find <keep> -delete` when the task is complete.

**Pause** when the user asks to stop or pause the task's work, not when they
correct one action:

1. Start nothing new. Send each running sub-agent (Claude Code: `SendMessage`):
   "Stop now. Stop your background jobs with TaskStop if you have it; leave
   detached jobs running. Write a handoff file in your scratch directory (a
   scratch note, allowed for read-only roles too; use a shell heredoc if you
   have no Write tool) with: your assignment as given (task, owned files, checks, acceptance criteria),
   what is done, findings so far, uncommitted changes, the next step, and each
   running job's log path and done condition. Then hand back once, ending with
   the line HANDOFF: <path>."
2. Start a background `agt wait --timeout 300 -- false` as a 5-minute timer and
   wait until every agent hands back or the timer ends. Then stop the timer,
   stop each agent still running with `TaskStop`, and mark it stopped without
   a handoff.
3. Stop your own background jobs by ID, except detached ones. Leave servers,
   worktrees, and uncommitted changes in place; a pause makes no commit.
4. Copy each agent's handoff file to `<keep>/agents/<agent-id>.md`, and
   `TODO.md` to `<keep>/TODO.md`. Write `<keep>/handoff.md`: this session's ID and title, worktree, branch, HEAD,
   `git status --short` summary, granted authorizations in their exact words,
   your next step, and each stopped job with its log, done condition, and how
   to restart it. Add one line per sub-agent: role, agent ID, description,
   status (handed off, stopped without handoff, or finished), its handoff copy
   or result path, and its transcript. `agt sessions search --session <your
   session id>` lists your transcript, `<session id>.jsonl`, under `sources`;
   sub-agent transcripts are
   `<transcript without .jsonl>/subagents/agent-<id>.jsonl`. In Claude Code,
   `sh ~/.claude/hooks/agent-tmux-session.sh custom <transcript>` prints the
   session title. A background
   `claude -p` session (`orchestrate`) counts as a job: record its request file
   and starting commit.
5. Create the task record when none exists. Then run
   `agt task update <id> --revision <n> --status paused --next-step "Continue per <keep>/handoff.md"`,
   with `<keep>` written out in full.
6. Report what stopped, each handoff, and each agent stopped without one.

**Continue** when the user asks to continue or resume paused work, such as
"continue the work now", in this session or a new one:

1. Use this session's paused task. A session with its own unpaused work goes
   on with that work, unless the user names paused work. Otherwise list records
   with `status: paused` in `agt task list`. Match a task or session the user
   names against record IDs, objectives, and the session line of each
   `<keep>/handoff.md`. With no name, take the only paused record for this
   repository; with several, ask.
2. Run `show` and validate it as above. Read `<keep>/handoff.md` and
   `<keep>/TODO.md`, keep the same `<task>` name, and restore `TODO.md` to
   `agents/output/<task>/` when it is gone. Then run
   `agt task update <id> --revision <n> --status active`.
3. Restart the stopped jobs that are still needed.
4. Never continue an old agent. For each agent not finished, spawn a fresh
   agent of the same role, per `sub-agents`, whose prompt starts: "Continue
   from session `<description>` (agent `<id>`). Read the handoff `<path>` first;
   it holds your assignment, state, and next step. Check it against the
   worktree before acting, and do not redo finished steps. Read only the end of
   the old transcript `<path>`, and only when the handoff lacks something you
   need." For an agent stopped without a handoff, pass its original assignment
   and transcript path instead. Restart a `claude -p` session with its request
   file and the commits made since its starting commit.
5. Continue your own work from the handoff's next step.

These session commands need `agt` 0.18.0 or newer. Follow [agt.md](../shared/agt.md).
For old context, run `agt sessions search` without `--query` to update the private incremental index and see scan
coverage (Codex and Claude history, transcripts, archives, alternate profiles, plus unreadable
or malformed files). After a deliberate rewrite deep inside a growing log, run `agt sessions search --rebuild`.
When a search needs three or more turns to read, run it through a `cheap` agent. It writes raw results to scratch and returns session ids, offsets, and one-line context; read the sessions you pick yourself.

Use `agt sessions search --session <id>` (no `--query`) to find an exact session. Use
`agt sessions search --query <text> [--session <id>]` to search human turns. Each
JSON-array result includes the host, session, source offset, and bounded context.
Search writes coverage JSON to standard error, including when it finds no match.
A `--session` lookup without `--query` includes coverage in its JSON object. Use `--file <path>` to add or
refresh one known transcript.

When the user asks to transfer a task between hosts, copy only its private JSON record
(`${XDG_STATE_HOME:-~/.local/state}/agents/tasks/<id>.json`) with `ssh`,
then set its mode to `0600`. Run `show` on the destination and validate the host,
repository, worktree, and HEAD before work. Do not copy transcripts or credentials.
The skill never starts remote commands automatically.
