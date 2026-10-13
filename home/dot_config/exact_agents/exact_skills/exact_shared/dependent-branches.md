# Separate work that depends on an unmerged pull request

Use a child branch when a separate task needs changes from an unmerged MR/PR.
Check the parent MR/PR's current state, repository, source branch, and head.
If it has merged, use the normal newest default base instead.

Fetch the unmerged parent's source branch and use that commit as the child's
base. Keep the parent's worktree and commits intact. Target the child's MR/PR
at the parent's branch, so its diff contains only the new task.
For a fork whose branch cannot be a target in this repository, report the
constraint before creating a child MR/PR; do not silently target the default.

Save the parent MR/PR URL, target branch, and task boundary in `agent-task`
with `--parent-pr`, `--target-branch`, and `--task-boundary` on create or update.
The boundary describes which requested change belongs in the child.
Reread that record when resuming, then check the parent state again.
An existing child's target remains authoritative unless the user requests
retargeting. Do not fold a separate task into the parent's MR/PR.

## Chains of dependent MRs/PRs

When several MRs/PRs depend on each other, make one linear chain: each targets
the branch directly below it, and the bottom targets the default branch. Never
base one on a branch that has no MR/PR of its own.

- GitHub: link the chain with `gh stack link <bottom> ... <top>`, from the
  `github/gh-stack` extension. After every PR in it has passing checks, run
  `gh stack merge <top> --squash --yes` (or the repo's method). That merges the
  chain bottom-up in one step, with no new CI run per layer. Stacks do not
  support auto-merge, so do not enable it on stacked PRs. Exit code 9 means
  the repository has not enabled stacked PRs; fall back to merging bottom-up,
  rebasing each child onto the default branch after its parent merges.
- GitLab: `glab stack` creates and syncs stacked MRs but is experimental and
  cannot merge a stack. Merge bottom-up; use a merge train when the project
  has one.
- A change in one area can need another area's MR/PR to land first, such as a
  webapp test that needs a CLI change compiled into WASM. Put both in the same
  chain, with the dependency lower.
