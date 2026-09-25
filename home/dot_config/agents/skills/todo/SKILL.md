---
disable-model-invocation: true
name: todo
description: >
  Add a one-line entry to TODO.md at the project root. Runs only when the user
  invokes it.
---

Add a todo item to `TODO.md` at the project root.

1. If no description argument was provided, reply "Error: /todo requires a description. Usage: /todo <description>" and stop.
2. Find the project root. In a Git repository, use the main checkout (the first `worktree` entry of `git worktree list --porcelain`), so the entry stays in the user's list after a linked worktree is removed. When that entry is marked `bare`, use `git rev-parse --show-toplevel`. Outside Git, look for `package.json` or a similar project marker; fall back to the current directory.
3. Append the item to the end of `TODO.md` as `- <description>`, creating the file with a `# TODO` header if it doesn't exist.
4. Keep the entry to one line: clear, specific, and actionable. Tighten vague input into an actionable item without changing its meaning.
