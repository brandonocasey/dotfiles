---
model: claude-sonnet-5-5
effort: medium
disable-model-invocation: true
name: worktree-cleanup
description: "Clean verified merged worktrees and branches; assess retained work. Other removals require confirmation."
---

`disk-cleanup` also runs this skill as a required step, under the limits in
[agent-resources.md](../disk-cleanup/references/agent-resources.md).

Clean only local state proven safe to remove. Use live PR state for GitHub or
GitLab repositories because squash merges break ancestry evidence. Report why
each target was retained. "PR" means a GitHub pull request or GitLab merge request.

## Safety rules

- Work locally. Never delete a remote branch, close a pull request, push, force-push, reset, or
  discard files as part of this skill.
- Protect the default branch, the current branch, and any branch checked out in the current
  worktree.
- Remove only worktrees that are clean (including no untracked files), attached to a named local
  branch, not in use by a running process, and unambiguous in path and identity — except an exact
  detached PR-head match covered by review confirmation. Force-remove only under the `worktree` skill's **Blocked removal** rules.
- Use `git branch -d` for branches whose tip is an ancestor of the selected local target. Let Git
  refuse deletion if that normal merge check fails.
- **Squash-merge exception**: `git branch -D` is allowed when the exact local tip equals a
  verified merged PR head, any attached worktree is clean and idle, and the branch has not moved
  since that PR.
- **Merged-PR-contained-history exception**: `git branch -D` is also allowed when the exact local
  tip is an ancestor of a verified merged PR head whose base/target and source-branch name match
  the local branch, and any attached worktree is clean and idle. This proves every commit
  reachable from the local tip was included in that PR. Recheck the exact tip immediately before
  deletion. Never use this exception when the local tip is a descendant of or diverges from the
  PR head, or when the PR head commit is unavailable locally.
- **Closed-without-merge exception**: `git branch -D` only after the user names the branch in
  the step 5 confirmation, the exact local tip equals the closed PR head, and any attached
  worktree is clean and idle. A confirmation never authorizes force-removing a worktree with Unknown blockers.
- **Review-worktree confirmation**: may remove every clean, idle worktree whose HEAD exactly
  matches a remote PR head, or is contained in a merged PR's head under the matching rules in
  step 3, including detached worktrees and multiple worktrees for one PR. It never authorizes deleting local branch refs unless those branches separately qualify.
- Do not infer that a branch is merged from its name, a closed-but-unmerged pull request, or a
  stale local ref.
- Retain a branch used by an open PR even if an older PR for that branch was merged.
- **Relevance findings are advice, not evidence.** A verdict of superseded or no longer useful
  from step 5 never authorizes deletion by itself. Such a branch may be removed only with
  `git branch -D` after the user names that branch and confirms, with the exact tip SHA recorded
  in the report so `git branch <name> <sha>` can restore it. Never remove a worktree on relevance
  grounds unless it is clean and idle.

## Workflow

### 1. Establish the repository and target

Run these checks before changing anything:

```sh
git rev-parse --show-toplevel
git rev-parse --abbrev-ref HEAD
git worktree list --porcelain
git status --short --ignore-submodules=none
git remote -v
```

Resolve **Local target name** in
[default-branch.md](../shared/default-branch.md). Cleanup proves ancestry in
that local target; it does not create a branch from the newest remote base.
Record the target worktree path and the checkout in which the skill is running.

Refresh remote-tracking refs when `origin` exists. This updates local evidence
and does not delete remote branches:

```sh
git fetch origin --prune
```

### 2. Build the candidate inventory

Read all worktrees from `git worktree list --porcelain`. For each worktree, record:

- absolute path;
- branch or detached state;
- HEAD commit;
- `git -C <path> status --short --ignore-submodules=none` output;
- whether a process has that path as its current directory.

On macOS or another system with `lsof`, inspect active directories with:

```sh
lsof -a -d cwd -Fpcn
```

Windows has no built-in equivalent that reports a process's current directory. If process
inspection is unavailable or inconclusive, retain the worktree and report that it was
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
  --json number,title,headRefName,headRefOid,headRepositoryOwner,isCrossRepository,state,mergedAt,baseRefName,url

# GitLab (any host; prefix with GITLAB_HOST=<host> when self-hosted)
glab api --paginate "projects/<url-encoded-project-path>/merge_requests?state=all&per_page=100"
```

GitLab fields map onto the same checks: `source_branch` → `headRefName`, `sha` → `headRefOid`
(the MR head), `state` (`merged`/`closed`/`opened`) with `merged_at` → `state`/`mergedAt`,
`target_branch` → `baseRefName`, `web_url` → `url`. A same-repository MR has
`source_project_id` equal to `target_project_id`; for fork MRs read
[forge-edge-cases.md](references/forge-edge-cases.md).

If the GitHub list reaches its limit, increase it until the result is complete.
Never narrow the list by date (`updated_after`, `created_after`, `--search "updated:>…"`) or any
other window; old merged PRs are the evidence for long-lived worktrees.
Check live open-PR state for each candidate before deletion; a truncated history
cannot prove that a branch has no open PR. A branch-name match counts only for a
same-repository PR (`isCrossRepository` false) or when the head owner matches the local branch's
upstream; fetch PR detail when needed.

Then look up every candidate the list did not match, so a missed page cannot hide a merged PR.
Look up branches by source branch, and detached or alias worktrees by HEAD commit:

```sh
# GitHub
gh pr list --state all --limit 1000 --head <branch> \
  --json number,headRefName,headRefOid,headRepositoryOwner,isCrossRepository,state,mergedAt,baseRefName,url
gh api --paginate "repos/<owner>/<repo>/commits/<sha>/pulls?per_page=100"

# GitLab
glab api --paginate "projects/<url-encoded-project-path>/merge_requests?source_branch=<url-encoded-branch>&state=all&per_page=100"
glab api --paginate "projects/<url-encoded-project-path>/repository/commits/<sha>/merge_requests?per_page=100"
```

`gh pr list --head` takes a bare branch name, so apply the same-repository rule to its results.
The commit lookups only suggest PRs. GitHub's may omit a squash-merged PR whose head never
reached the default branch. Confirm every suggestion against that PR's `headRefOid` with the
checks below; a missing suggestion proves nothing.

For a local branch to qualify from PR evidence, all of these must be true:

- state is merged;
- a merged timestamp is present;
- the base/target branch is the selected target;
- the head/source branch name matches the local branch name;
- the PR head commit is available locally; and
- the local branch tip either exactly equals the PR head SHA or is an ancestor of it, verified with:
  `git merge-base --is-ancestor <local-tip> <pr-head>`.

If the PR head is missing locally after `git fetch origin` (deleted source branch), fetch it
as [forge-edge-cases.md](references/forge-edge-cases.md) describes.

`git merge-base --is-ancestor` exits 0 for a match and 1 for no match. A failed fetch, a SHA
mismatch, a shallow-history boundary, or any other exit code makes the evidence unknown:
retain the candidate.

If the local tip is an ancestor of the PR head, report that the merged PR contains the complete
local commit history. If the ancestry check fails, retain it and explain that the local history
is newer or diverged from the merged PR. List it as `keep` with reason `diverged from merged
PR #<n>`, not as unmerged work: step 5 runs
[rebased-history.md](references/rebased-history.md) on it, which separates a rebased copy of the
squash-merged PR from commits the PR never had.

#### Closed without merge and review worktrees

Read [forge-edge-cases.md](references/forge-edge-cases.md) when a PR is closed without merge or
a worktree may be a remote-PR review checkout (detached, or on a branch whose name differs from the
PR's source branch). It covers recording those candidates and the review-worktree question.

#### No usable PR evidence

Local ancestry is sufficient only when the branch tip is an ancestor of the selected target:

```sh
git merge-base --is-ancestor <branch> <target>
```

If that check fails, retain the branch. Without forge state, retain
squash-merged branches rather than guess.

### 4. Filter and confirm

A worktree is removable only when its category has evidence — local ancestry in the
selected target, a merged PR whose head contains every local commit, a user-confirmed
exact closed-PR head, or a user-confirmed review match — and every safety rule passes.
A local branch without a worktree can qualify through local ancestry, merged-PR
evidence, or a user-confirmed exact closed-without-merge head. Current, target,
open-PR, and otherwise protected branches remain protected in every category.

Before mutating anything, show a compact table with `remove`, `keep`, and `reason` for every
candidate. Every `keep` row then goes through step 5. If the user asked for a dry run, show the step 5
assessment, ask nothing, and stop. Otherwise ask the user to approve the `remove` rows before step 6. Ask in the
same message as the step 5 question when step 5 asks one.

### 5. Assess retained candidates

Read [assess-retained.md](references/assess-retained.md) when step 4 retains any candidate.
Complete its assessment and required confirmations before removal.

### 6. Remove one target at a time

For each approved worktree, recheck its path, branch, cleanliness, and HEAD immediately before
removal, then remove it:

```sh
git worktree remove -- <worktree-path>
```

If the repository provides a purpose-built helper such as `scripts/remove-worktree.mjs`, inspect
its behavior and use it when it is the project's documented path. If removal refuses, follow the
`worktree` skill's **Blocked removal** section: force only when every blocker is Saved or
Disposable; otherwise retain the target and report the exact reason.

After the worktree is gone, decide separately whether its local branch is eligible under the
safety rules (a review-worktree confirmation alone means keep an attached local branch; detached
worktrees have no branch to delete). Evaluate local branches without worktrees as independent
cleanup targets too; do not retain them merely because no worktree is attached. For every eligible
branch, recheck its current tip, protection status, merged-PR evidence, and attached worktree
state immediately before deletion. Delete eligible branches from the checkout that has the target
branch when that worktree exists, so Git's normal deletion check uses the target tip. A branch
with an upstream is checked against that upstream instead, so `-d` may refuse a branch merged
only locally — retain it and report why:

```sh
git -C <target-worktree-path> branch -d -- <branch>   # local ancestry proves the merge
git -C <target-worktree-path> branch -D -- <branch>   # exact-head or contained-history exception
```

Before any `-D`, recheck the matching exception's exact-tip and state conditions (including
the ancestry check for contained-history cleanup) and report which exception backed it: exact
squash-merged PR head, merged-PR-contained history, user-confirmed closed-without-merge head, or
user-confirmed relevance removal (named-branch confirmation and recorded recovery tip from
step 5). If the target branch is not checked out anywhere, retain candidates requiring `-d`
rather than switching a user's checkout; a `-D` exception may use the current checkout instead.

After each successful mutation, refresh and show:

```sh
git worktree list --porcelain
git branch --list
git worktree prune --dry-run
```

Use `git worktree prune` only to remove stale administrative records after checking that no
valid worktree path is missing. Do not overlap removal commands; wait for each command to finish.

### 7. Report the final state

End with:

- every removed worktree and local branch;
- every removed review worktree grouped by PR, including duplicate paths for the same PR;
- every retained candidate and the reason it was retained;
- the step 5 verdict for every retained branch, with the evidence behind it and the tip SHA of
  every branch removed on relevance grounds;
- the final worktree and branch inventory;
- a statement that remote branches were not changed;
- any inconclusive checks, such as unavailable forge or process evidence.

Do not claim that all merged work is clean if any candidate was retained or any check was
inconclusive.
