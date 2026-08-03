---
name: clean-merged-worktrees
description: >
  Safely clean local Git worktrees and branches after their changes have been merged.
  Use when the user asks to clean up merged worktrees, stale merged branches, or completed
  local checkout pairs. Ask before cleaning closed-without-merge PR branches. Preserve dirty,
  active, detached, open-PR, review, and ambiguous work unless separately confirmed.
---

# Clean Merged Worktrees

Clean only local state that is demonstrably safe to remove. Use live pull-request state when the
repository has GitHub or GitLab metadata, because squash merges do not make the original branch an
ancestor of the default branch. Report every retained target and why it was skipped. "PR" below
means a GitHub pull request or a GitLab merge request.

## Safety rules

These rules are the single authority; the workflow steps reference them instead of restating them.

- Work locally. Never delete a remote branch, close a pull request, push, force-push, reset, or
  discard files as part of this skill.
- Protect the default branch, the current branch, and any branch checked out in the current
  worktree.
- Remove only worktrees that are clean (including no untracked files), attached to a named local
  branch, not in use by a running process, and unambiguous in path and identity — except an exact
  detached PR-head match covered by review confirmation. Never use `git worktree remove --force`.
- Use `git branch -d` for branches whose tip is an ancestor of the selected local target. Let Git
  refuse deletion if that normal merge check fails.
- **Squash-merge exception**: `git branch -D` is allowed only when the exact local tip equals a
  confirmed merged PR head, the worktree is clean and idle, and the branch has not moved since
  that PR. Never use `-D` for a branch that is merely closed, named like a feature, or believed
  to be merged.
- **Closed-without-merge exception**: `git branch -D` only after the user explicitly confirms this
  category, the exact local tip equals the closed PR head, and the branch is clean and idle. A
  confirmation never authorizes force-removing a dirty worktree.
- **Review-worktree confirmation**: may remove every clean, idle worktree whose HEAD exactly
  matches a remote PR head, including detached worktrees and multiple worktrees for one PR. It
  never authorizes deleting local branch refs unless those branches separately qualify.
- A merged PR is proof only for the exact PR head commit. If the local branch has moved beyond
  that commit, keep it — it may contain new work.
- Do not infer that a branch is merged from its name, a closed-but-unmerged pull request, or a
  stale local ref.

## Workflow

### 1. Establish the repository and target

Run these checks before changing anything:

```sh
git rev-parse --show-toplevel
git rev-parse --abbrev-ref HEAD
git worktree list --porcelain
git status --short
git remote -v
```

Determine the default target in this order:

1. `origin/HEAD`, if it resolves to a local remote-tracking branch.
2. Local `main`, if it exists.
3. Local `master`, if it exists.

If no target can be established, stop and ask. Do not choose a branch from naming convention
alone. Record the target worktree path and the checkout in which the skill is running.

Refresh remote-tracking refs when an `origin` remote exists (this refreshes local evidence; it
does not delete remote branches):

```sh
git fetch origin --prune
```

### 2. Build the candidate inventory

Read all worktrees from `git worktree list --porcelain`. For each worktree, record:

- absolute path;
- branch or detached state;
- HEAD commit;
- `git -C <path> status --short` output;
- whether a process has that path as its current directory.

On macOS or another system with `lsof`, inspect active directories with:

```sh
lsof -a -d cwd -Fpcn
```

If process inspection is unavailable or inconclusive, retain the worktree and report that it was
not safe to prove idle.

Also list local branches with their upstreams and tips:

```sh
git for-each-ref --format='%(refname:short) %(objectname:short) %(upstream:short)' refs/heads
```

### 3. Establish merge evidence

When the remote points to GitHub or GitLab and the matching CLI is authenticated, use the forge's
merged-PR state as the authority for squash-merged branches:

```sh
# GitHub
gh pr list --state all --limit 1000 \
  --json number,title,headRefName,headRefOid,state,mergedAt,baseRefName,url

# GitLab (any host; prefix with GITLAB_HOST=<host> when self-hosted)
glab api --paginate "projects/<url-encoded-project-path>/merge_requests?state=all&per_page=100"
```

GitLab fields map onto the same checks: `source_branch` → `headRefName`, `sha` → `headRefOid`
(the MR head), `state` (`merged`/`closed`/`opened`) with `merged_at` → `state`/`mergedAt`,
`target_branch` → `baseRefName`, `web_url` → `url`.

For a local branch to qualify from PR evidence, all of these must be true:

- state is merged;
- a merged timestamp is present;
- the base/target branch is the selected target;
- the head/source branch name matches the local branch name;
- the local branch tip exactly equals the PR head SHA.

If the branch tip differs from the PR head, retain it and explain that it changed after the
merged PR. Do not delete it merely because the old PR was merged.

#### Closed without merge

Classify a PR as closed-without-merge only when its state is closed and it has no merged
timestamp; open PRs and merged PRs never fall in this category. These branches are never part of
ordinary merged cleanup. If any local worktree or branch tip exactly equals such a PR's head, show
the PR number, title, URL, branch, head SHA, worktree path, and clean/active status, then ask:

> Do you also want to remove the clean, idle local worktrees and branches for PRs that were closed
> without merging? This does not remove remote branches or discard dirty or active work.

Wait for the answer before mutating anything. A `yes` authorizes exactly what the
closed-without-merge safety rule allows. Anything else — `no`, no answer, changed tip, dirty
worktree, active process, detached worktree, ambiguous mapping — means keep the target and report
why.

#### Remote-PR review worktrees

A worktree used to review a remote PR may be detached or may use a local branch name different
from the PR's source branch. Match it by exact HEAD equality with any PR's head SHA, regardless of
PR state or base branch. Group matches by PR number, but evaluate every filesystem path
independently — do not deduplicate multiple worktrees for the same PR.

For every matching worktree, show the PR number, title, URL, state, head SHA, worktree path,
branch or detached state, and clean/active status, then ask:

> Do you also want to remove clean, idle review worktrees whose HEAD matches a remote pull-request
> head, including multiple local worktrees for the same PR? This removes only local worktrees. It
> does not delete remote branches or local branch refs unless they are separately eligible.

Wait for the answer before removing review worktrees. A `yes` authorizes each exact, clean, idle
match per the review-worktree safety rule — never the current checkout or the target worktree.
Anything else — `no`, no answer, changed HEAD, dirty worktree, active process, missing PR
evidence, ambiguous mapping — means keep the worktree and report why.

#### No usable PR evidence

Local ancestry is sufficient only when the branch tip is an ancestor of the selected target:

```sh
git merge-base --is-ancestor <branch> <target>
```

If that check fails, retain the branch. This deliberately leaves squash-merged branches in place
when forge state is unavailable rather than guessing.

### 4. Filter and confirm

A worktree is removable only when its category has confirmed evidence — a merged PR, a
user-confirmed exact closed-PR head, or a user-confirmed review match — AND every safety rule
passes. A local branch without a worktree is removable only with confirmed merged-PR evidence or
a user-confirmed exact closed-without-merge head, and never when it is the current, target, or
otherwise protected branch — even if an unusual repository state makes it look eligible.

Before mutating anything, show a compact table with `remove`, `keep`, and `reason` for every
candidate. If the user asked for a dry run, stop after this table.

### 5. Remove one target at a time

For each approved worktree, recheck its path, branch, cleanliness, and HEAD immediately before
removal, then remove it without force:

```sh
git worktree remove -- <worktree-path>
```

If the repository provides a purpose-built helper such as `scripts/remove-worktree.mjs`, inspect
its behavior and use it when it is the project's documented path. If removal refuses because the
tree is dirty or otherwise unsafe, retain the target and report the exact reason.

After the worktree is gone, decide separately whether its local branch is eligible under the
safety rules (a review-worktree confirmation alone means keep an attached local branch; detached
worktrees have no branch to delete). Delete eligible branches from the checkout that has the
target branch when that worktree exists, so Git's normal deletion check uses the target tip:

```sh
git -C <target-worktree-path> branch -d -- <branch>   # local ancestry proves the merge
git -C <target-worktree-path> branch -D -- <branch>   # only under an exact-PR-head exception
```

Before any `-D`, re-verify the matching exception's exact-tip and state conditions immediately
before the command, and report which exception — squash-merged PR head, or user-confirmed
closed-without-merge head — backed the forced local ref deletion. If the target branch is not
checked out anywhere, retain candidates requiring `-d` rather than switching a user's checkout;
an explicitly confirmed exact PR-head deletion may use `-D` from the current checkout instead.

After each successful mutation, refresh and show:

```sh
git worktree list --porcelain
git branch --list
git worktree prune --dry-run
```

Use `git worktree prune` only to remove stale administrative records after confirming that no
valid worktree path is missing. Do not overlap removal commands; wait for each command to finish.

### 6. Report the final state

End with:

- every removed worktree and local branch;
- every removed review worktree grouped by PR, including duplicate paths for the same PR;
- every retained candidate and the reason it was retained;
- the final worktree and branch inventory;
- confirmation that remote branches were not changed;
- any inconclusive checks, such as unavailable forge or process evidence.

Do not claim that all merged work is clean if any candidate was retained or any check was
inconclusive.
