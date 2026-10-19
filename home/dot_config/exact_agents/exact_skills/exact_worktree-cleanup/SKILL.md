---
model: claude-sonnet-5-5
effort: medium
disable-model-invocation: true
name: worktree-cleanup
description: "Clean verified merged worktrees and branches; assess retained work. Other removals require confirmation."
---

`disk-cleanup` also runs this skill as a required step, under the limits in
[agent-resources.md](../disk-cleanup/references/agent-resources.md).

This needs `agt` 0.10.0 or newer ([agt.md](../shared/agt.md)). `agt worktree cleanup` finds, judges,
backs up, and removes landed worktrees and branches; this skill adds what it does not do.

Clean only local state proven safe to remove. Use live PR state for GitHub or
GitLab repositories because squash merges break ancestry evidence. Report why
each target was retained. "PR" means a GitHub pull request or GitLab merge request.

## Safety rules

- Work locally. Never delete a remote branch, close a pull request, push, force-push, reset, or
  discard files as part of this skill.
- `agt worktree cleanup` owns the inventory, idle checks (processes and live Claude Code sessions),
  merge evidence, `git branch -d`/`-D` rules, and worktree removal. It never touches the default
  branch, the main checkout's branch, the current branch, or the worktree holding the current
  directory. Do not redo its checks by hand, and never delete a branch or force-remove a
  worktree it kept, except under the confirmations below.
- Pass `--offline` only when the forge is unreachable; the plan then trusts local ancestry only.
  Pass `--all` only when the user asked for every repository. Always pass `--dirty` and
  `--recent`: they only lift guards on merged rows, and the snapshot backup keeps their work.
  Report each removed dirty worktree's changed files with its backup id.
- When removal fails with "does not point back", the worktree belongs to another clone: its
  `.git` file names the owning repository. Run the plan and removal from that repository, then
  `git worktree prune` in the first one.
- **Closed-without-merge exception**: `git branch -D` only after the user names the branch in
  the step 5 confirmation and the exact local tip equals the closed PR head.
- **Review-worktree confirmation**: may remove every worktree whose HEAD exactly matches a remote
  PR head, or is contained in a merged PR's head under the matching rules in
  [forge-edge-cases.md](references/forge-edge-cases.md), including detached worktrees and multiple
  worktrees for one PR, with `agt worktree remove <path> --yes` for each. It never authorizes
  deleting local branch refs unless those branches separately qualify.
- **Named detached-baseline confirmation**: outside review, removal requires explicit approval
  naming the detached path and HEAD, with that commit preserved in the remaining main checkout
  or a named local ref that will remain. A baseline label or target ancestry alone is not approval.
- Do not infer that a branch is merged from its name, a closed-but-unmerged pull request, or a
  stale local ref.
- **Relevance findings are advice, not evidence.** A verdict of superseded or no longer useful
  from step 5 never authorizes deletion by itself. Such a branch may be removed only with
  `git branch -D` after the user names that branch and confirms, with the exact tip SHA recorded
  in the report so `git branch <name> <sha>` can restore it. Never remove a worktree on relevance
  grounds unless `agt worktree remove` accepts it and the user confirms.

## Workflow

### 1. Establish the repository and plan

```sh
git rev-parse --show-toplevel
git worktree list --porcelain
agt worktree list          # dirty counts, ahead/behind, merged state
```

Run the plan, which changes nothing but fetching PR heads into the object store:

```sh
agt worktree cleanup --dirty --recent [--all] [--offline]
```

Record the checkout in which the skill is running. Resolve **Local target name** in
[default-branch.md](../shared/default-branch.md) when step 5 needs a target for ancestry checks.

### 2. Read the plan

The plan lists, per repository, `remove` and `delete` candidates (each with its `verdict`,
`evidence`, and exact `action`), `kept` rows with reasons, and `warnings`. The verdicts are `merged`,
`squash-merged`, `open`, `closed`, `diverged`, `unknown`, and `unmerged`. A worktree is kept as `dirty`,
`recent`, locked, in use by another process or Claude Code session, or holding a submodule `remove`
refuses. The calling session's own processes do not keep a worktree: agt lists them under the
repository's `warnings` with `(of the calling session)`. Take every `kept` row as a retained candidate. Also list worktrees and branches the plan
did not mention, with `agt worktree list`, as explicit keeps, never omissions.

### 3. Merge evidence

agt asks the forge for every PR/MR of each branch and applies the same-repository, base,
head-commit, and ancestry rules. Do not redo these checks, and do not query the forge again for
rows it judged. Query the forge only for what agt does not judge: closed-without-merge details
beyond its `head`, `title`, and `closed_at`, and review-worktree matching by PR head SHA. For the
retained rows:

- `closed`: read [forge-edge-cases.md](references/forge-edge-cases.md) **Closed without merge**.
- `diverged from merged PR #<n>`: step 5 runs [rebased-history.md](references/rebased-history.md)
  on it. List it as `keep`, not as unmerged work.
- `unknown` (failed forge call, head mismatch): retain it and report why. Rerun the plan once
  if the failure looks transient.
- A worktree that may be a remote-PR review checkout (detached, or on a branch whose name differs
  from the PR's source branch): read [forge-edge-cases.md](references/forge-edge-cases.md)
  **Remote-PR review worktrees**.

Without forge state (`--offline` or an unsupported host), only a branch whose tip is an ancestor
of the target counts as merged; retain squash-merged branches rather than guess.

### 4. Show the plan and confirm

Before mutating anything, show a compact table with `remove`, `keep`, and `reason` for every
candidate, from the plan plus any review-worktree or detached-baseline rows. Show every `(of the calling session)` warning in it. Before step 6, stop
those task processes per
[task-resources.md](../host-preflight/references/task-resources.md), or keep a worktree that a
live preview still needs. Every `keep` row
then goes through step 5. If the user asked for a dry run, show the step 5 assessment, ask
nothing, and stop. Otherwise the `remove` and `delete` rows with verdict `merged` or
`squash-merged` are approved by the cleanup request: run step 6 on them without asking. Ask
approval only for the other rows and exceptions, in the same message as the step 5 question
when step 5 asks one. Include each named
detached-baseline exception with its HEAD-preservation proof. Only the approved rows and
dispositions are authorized; changed scope needs a new preview.

### 5. Assess retained candidates

Read [assess-retained.md](references/assess-retained.md) when step 4 retains any candidate.
Complete its assessment and required confirmations before removal.

### 6. Remove

Run the same plan flags with `--yes`, limited to the approved rows. Pass
`--only` once for each approved branch or path. Never run a bare `--yes`: the plan may have
changed since the user approved it. Naming a branch also removes its worktree, because git cannot
delete a checked-out branch. When the user approved the branch but not its worktree, ask before
this step. With `--all`, run this step inside each repository without
`--all`, and pass only that repository's approved names. Naming a worktree also deletes its landed
branch. When the user approved only the worktree, run `agt worktree remove <path> --yes` instead.

```sh
agt worktree cleanup --dirty --recent [--offline] --yes --only <branch-or-path> [--only <branch-or-path> ...]
```

It snapshots each worktree (a commit pinned at `refs/agt/backups/<id>` plus copies of
non-disposable ignored files), removes it, then deletes the branches that qualify with `-d`, or
`-D` for a verified squash merge, and prints `removed` (with the backup `id`), `deleted` (with
each `tip` and the `git branch <name> <tip>` that restores it), `kept`, and `warnings`. A named row
that no longer qualifies with the same verdict is skipped. Report each skipped row and why. Show a
new plan before acting on it.

Then handle what agt kept, one target at a time, after a fresh recheck of its path, HEAD, and tip:

- For a confirmed review-worktree or detached-baseline row:
  `agt worktree remove <path> --yes`. If it refuses, follow the `worktree` skill's
  **Blocked removal** section and retain the target.
- After each `agt worktree remove`, when `head_on_local_branch` and `head_on_remote_branch` are
  both false, report the HEAD commit and `refs/agt/backups/<id>` per
  [remove.md](../worktree/references/remove.md).
- For a user-named closed-without-merge or relevance branch: record the tip SHA. When a worktree
  has the branch checked out, first run `agt worktree remove <path> --yes`; if it refuses, keep
  the worktree and the branch and report the refusal. Then
  `git -C <target-worktree-path> branch -D -- <branch>`. Name the exception in the report.
  Delete from a checkout that is not on the branch; if none exists, use the current checkout.

Refresh and show the result:

```sh
agt worktree list
git branch --list
```

Do not overlap removal commands; wait for each command to finish.

### 7. Report the final state

End with:

- every removed worktree with its backup id (and, when its HEAD is on no branch, the HEAD commit
  and `refs/agt/backups/<id>`), and every deleted local branch with its tip;
- every removed review worktree grouped by PR, including duplicate paths for the same PR;
- every retained candidate and the reason it was retained;
- the step 5 verdict for every retained branch, with the evidence behind it and the tip SHA of
  every branch removed on relevance grounds;
- the final worktree and branch inventory;
- a statement that remote branches were not changed;
- any inconclusive checks, such as unavailable forge or process evidence.

Do not claim that all merged work is clean if any candidate was retained or any check was
inconclusive.
