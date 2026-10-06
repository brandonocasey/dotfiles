# Multiple branches

With several branch names
or `all`, ship each branch in turn, a parent before its dependent children.
For `all`, list the branches that have a `.worktrees/` worktree with a clean
tree and commits ahead of `TARGET`. Exclude worktrees another task uses. Show
each branch with its ahead count and ask once before the first push. Other
argument text is a task to finish first.
