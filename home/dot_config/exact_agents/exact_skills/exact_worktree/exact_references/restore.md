### Restore a removed worktree

Reuse a retained worktree for CI fixes or review feedback. If it was removed
by `agt worktree remove` or `cleanup`, restore it from its backup (needs `agt` 0.10.0;
[agt.md](../../shared/agt.md)):

```sh
agt worktree restore <id>            # the id remove printed
agt worktree backups                 # find the id; `backups <id>` for one record
```

It recreates the worktree at its original path (or `--path`) with its branch
and its uncommitted work, and refuses an existing path. Ignored files are not
restored, except from backups made by agt 0.20.0 or older. Reinstall dependencies per [prepare.md](prepare.md).

Without a backup, check `git worktree list --porcelain` and whether the local
branch still exists. Read [create.md](create.md) for an existing branch. Only
when the branch was also deleted:

```sh
git -C <main-checkout> fetch origin <branch>:refs/remotes/origin/<branch>
git -C <main-checkout> worktree add --track -b <branch> .worktrees/<branch> origin/<branch>
```

Then set up submodules per [create.md](create.md).
