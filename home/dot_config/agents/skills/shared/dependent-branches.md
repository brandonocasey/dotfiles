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
