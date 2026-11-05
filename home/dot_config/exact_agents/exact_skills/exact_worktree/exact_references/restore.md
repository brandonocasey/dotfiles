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

Without a backup, check `git worktree list --porcelain`, whether the local branch still
exists, and `git -C <main-checkout> ls-remote --exit-code origin "refs/heads/<branch>"`. When
the branch exists locally or on origin, follow [create.md](create.md): `agt worktree create <branch>`
reuses it or tracks the origin branch, and sets up submodules. When it exists in neither place,
report that and do not create a new branch.
