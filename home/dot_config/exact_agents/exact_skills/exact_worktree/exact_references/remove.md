## Remove

This needs `agt` 0.10.0 or newer. Follow [agt.md](../../shared/agt.md).

Keep worktrees and branches for open MRs/PRs unless the user requests cleanup.
Exception: remove a review worktree this review created when the review ends,
even for an open MR/PR, unless the review installed dependencies in it.

Remove a task worktree after merge or closure, or on explicit cleanup. Never
remove the main checkout, a locked worktree, or one another task uses. Report
retained paths and reasons or the removed path.

`agt worktree remove` backs the worktree up before it removes it, so dirty and
untracked work is kept: no separate check of it is needed. Ignored files are not
backed up. The plan and the result list the ones no build recreates (`.env*`,
credentials, notes) as `ignored_lost`; read that list before `--yes` (needs `agt`
0.21.0) and copy out what is needed. For a remote MR/PR, fetch and refresh its
state before using merged/closed status.

Take `<worktree-path>` from `agt worktree list` (older worktrees can live
elsewhere). Move your shell out first: a shell in the deleted directory makes
later commands fail with "Unable to read current working directory". Then plan,
read the plan, and remove:

```sh
cd <main-checkout>
agt worktree remove <worktree-path>          # plan only: refusals, nothing changes
agt worktree remove <worktree-path> --yes
```

- The plan lists what agt refuses: the main checkout, a locked worktree, a path
  that is not a linked worktree, the current directory, a worktree where another
  process or another Claude Code session runs (agt ignores your own session and its processes), and
  a submodule problem, or a directory git could not empty (unreadable or read-only; fix its
  permissions with the `chmod -R u+rwX` the error names). When it refuses, follow
  **Blocked removal** in [removal-checks.md](removal-checks.md).
- When the plan's `hooks.remove` lists commands, `--yes` runs them first; a failing one stops the
  removal: report its command and log. Report `hooks.untrusted` as
  [prepare.md](prepare.md) says. Pass `--no-hooks` only when the user asks.
- `--yes` snapshots the working tree as a commit pinned at `refs/agt/backups/<id>`,
  saves its record under
  `~/.local/state/agents/backups/<repo>/<stamp>-worktree-<name>/`, then runs
  `git worktree remove --force`, which deletes the ignored files. Report the backup `id`
  and that `agt worktree restore <id>` brings the worktree back.
- When the result reports `head_on_local_branch` and `head_on_remote_branch` both
  false, the HEAD commit is on no branch. Report the HEAD commit ID and the backup ref
  `refs/agt/backups/<id>`: those commits live only there.
- It never deletes the branch. Delete a local branch only through **Remove after
  push** below, `land`'s merged branch checks, the wrong-base cleanup in
  [create.md](create.md), or the `-D` exceptions in `review`
  step 7 and in a user-invoked `worktree-cleanup` run. If a deleted remote branch
  prevents that proof, retain the local branch; the worktree can still be removed.
  A squash merge does not prove the original commits are on the branch. Outside
  those exceptions, never force-delete a branch to finish cleanup.

Follow [task-resources.md](../../host-preflight/references/task-resources.md) for
task processes, scratch, and preview retention, even when retaining an open-PR
worktree. Run that cleanup separately from approve, merge, ticket, or other outward
steps, so a blocked outward step cannot prevent it.

### Remove after push

Use only after **Remove** permits cleanup: the MR/PR is merged or closed, or
the user explicitly requested it. A push alone is not a cleanup trigger.
When the remote source branch still exists, prove it holds the local tip:

```sh
git -C <main-checkout> ls-remote origin refs/heads/<branch>   # remote tip
git -C <main-checkout> rev-parse <branch>                     # local tip; must be the same ID
```

Pass the full ref: a bare `<branch>` pattern also matches
`refs/heads/<prefix>/<branch>` and can print a second ID.
If the IDs differ or the command fails, keep the worktree and the branch and
report both IDs. When `ls-remote` prints nothing, keep the branch; remove the
worktree per **Remove**. Otherwise remove the worktree per **Remove**, then:

```sh
git -C <main-checkout> branch -d <branch>
```

`branch -d` checks the branch against its upstream and refuses a tip the
upstream lacks; report the refusal, never answer it with `-D`. The upstream
must be set (`git push -u` sets it). Without one, `-d` checks against HEAD and
refuses a pushed branch: run `git branch -u origin/<branch> <branch>` and retry
`-d` once. Report the removed path, the backup id, and the branch's last commit
ID; the remote branch keeps the history.
