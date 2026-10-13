# Forge edge cases

Read from step 3 of [SKILL.md](../SKILL.md) when a candidate involves a fork MR, a PR head
missing locally, a PR closed without merge, or a worktree that may be a remote-PR review checkout.

## Fork MRs

For a fork MR, match `source_project_id` to the local branch's upstream project.

## PR head missing locally

A deleted source branch often leaves the PR head missing after `git fetch origin`. Fetch it
through the PR ref from the remote that hosts the PR's base repository. Confirm that
`git rev-parse FETCH_HEAD` equals the head SHA from this run's PR data, then pass that SHA,
not a ref name, to later checks; the fetch creates no ref:

```sh
git fetch <base-remote> refs/pull/<number>/head            # GitHub
git fetch <base-remote> refs/merge-requests/<iid>/head     # GitLab
git cat-file -e <pr-head-sha>^{commit}
```

## Closed without merge

Classify a PR as closed-without-merge only when its state is closed and it has no merged
timestamp; open PRs and merged PRs never fall in this category. These branches are never part of
ordinary merged cleanup and are never removed in step 6 without the confirmation collected in
step 5. Record every local branch whose name matches such a PR's source branch, and every branch
or worktree whose tip exactly equals such a PR's head, with the PR number, title, URL, head SHA,
close date, and closing comment when the CLI exposes one. Step 5 assesses them with the other
retained candidates and asks one question for all of them.

## Remote-PR review worktrees

A worktree used to review a remote PR may be detached or may use a local branch name different
from the PR's source branch. Match it by exact HEAD equality with any PR's head SHA, regardless of
PR state or base branch. A HEAD that is an ancestor of a PR head also matches when the PR is
merged, its base is the selected target, and the HEAD is not already an ancestor of that target,
because a review often stops before the PR's last push. Check it with the fetch above and the
`--is-ancestor` rules in step 3. A HEAD contained in more than one such PR is an ambiguous mapping.
Group matches by PR number, but evaluate every filesystem path independently; do not deduplicate
multiple worktrees for the same PR.

For every matching worktree, show the PR number, title, URL, state, head SHA, worktree path,
branch or detached state, and clean/active status, then ask:

> Do you also want to remove clean, idle review worktrees whose HEAD matches a remote pull-request
> head or is contained in a merged one, including multiple local worktrees for the same PR? This
> removes only local worktrees, not remote branches or local branch refs.

Wait for the answer before removing review worktrees. A `yes` authorizes each clean, idle match
per the review-worktree safety rule, never the current checkout or the target worktree. Anything
else (`no`, no answer, changed HEAD, dirty worktree, active process, missing PR evidence,
ambiguous mapping) means keep the worktree and report why.
