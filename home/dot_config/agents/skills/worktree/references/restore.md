### Restore a removed worktree

Reuse a retained worktree for CI fixes or review feedback. If it was removed,
check `git worktree list --porcelain` and whether the local branch still exists.
Read [create.md](../references/create.md) for an existing branch. Only when the branch was also deleted:

```sh
git -C <main-checkout> fetch origin <branch>:refs/remotes/origin/<branch>
git -C <main-checkout> worktree add --track -b <branch> .worktrees/<branch> origin/<branch>
```
