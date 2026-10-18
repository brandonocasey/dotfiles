# Forge edge cases

Read from step 3 of [SKILL.md](../SKILL.md) when a candidate that `agt worktree cleanup` kept involves a fork MR, a PR head
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

## Listing PRs

Use these only for what agt does not judge. List every state, never a date window, and paginate
to the end. A truncated list proves nothing; treat it as inconclusive.

```sh
gh api --paginate "repos/<owner>/<repo>/pulls?state=all&per_page=100"
glab api --paginate "projects/<url-encoded-path>/merge_requests?state=all&per_page=100"
```

A lookup from a commit to its PRs (`gh api repos/<owner>/<repo>/commits/<sha>/pulls`) is only a
suggestion. Confirm each hit against the full list.

## Closed without merge

agt reports each `closed` row with the PR's `head`, `title`, and `closed_at`. Classify a PR as
closed-without-merge only when its state is closed and it has no merged
timestamp; open PRs and merged PRs never fall in this category. Look up the rest from the full list
above. Record every local branch whose name matches such a PR's source branch, and every branch
or worktree whose tip exactly equals such a PR's head, with the PR number, title, URL, head SHA,
close date, and closing comment when the CLI exposes one. Step 5 assesses them with the other
retained candidates.

## Remote-PR review worktrees

A worktree used to review a remote PR may be detached or may use a local branch name different
from the PR's source branch. Match it by exact HEAD equality with any PR's head SHA, regardless of
PR state or base branch. A HEAD that is an ancestor of a PR head also matches when the PR is
merged, its base is the selected target, and the HEAD is not already an ancestor of that target,
because a review often stops before the PR's last push. Check it with the fetch above and the
`git merge-base --is-ancestor` check (exit 0 matches, 1 does not, anything else is unknown). A HEAD contained in more than one such PR is an ambiguous mapping.
Group matches by PR number, but evaluate every filesystem path independently; do not deduplicate
multiple worktrees for the same PR.

For every matching worktree, show the PR number, title, URL, state, head SHA, worktree path,
branch or detached state, and clean/active status, then ask:

> Do you also want to remove clean review worktrees whose HEAD matches a remote pull-request
> head or is contained in a merged one, including multiple local worktrees for the same PR? This
> removes only local worktrees, not remote branches or local branch refs.

Wait for the answer before removing review worktrees. A `yes` authorizes each clean match
per the review-worktree confirmation, with `agt worktree remove <path> --yes`, never the current checkout or the target worktree. agt
refuses a worktree where another process or Claude Code session runs; keep it and report agt's
reason. Anything else (`no`, no answer, changed HEAD, dirty worktree, missing PR evidence,
ambiguous mapping) also means keep the worktree and report why.
