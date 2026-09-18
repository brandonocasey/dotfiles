---
disable-model-invocation: true
name: clean-merged-worktrees
description: >
  Clean local worktrees and branches after verified merges, then assess every
  retained branch as still relevant, superseded, or no longer useful. Use for
  merged-work cleanup; closed-without-merge, review, and relevance-based
  removal need separate confirmation.
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
  detached PR-head match covered by review confirmation. Force-remove only under the `worktree` skill's **Blocked removal** rules.
- Use `git branch -d` for branches whose tip is an ancestor of the selected local target. Let Git
  refuse deletion if that normal merge check fails.
- **Squash-merge exception**: `git branch -D` is allowed when the exact local tip equals a
  confirmed merged PR head, any attached worktree is clean and idle, and the branch has not moved
  since that PR.
- **Merged-PR-contained-history exception**: `git branch -D` is also allowed when the exact local
  tip is an ancestor of a confirmed merged PR head whose base/target and source-branch name match
  the local branch, and any attached worktree is clean and idle. This proves every commit
  reachable from the local tip was included in that PR. Recheck the exact tip immediately before
  deletion. Never use this exception when the local tip is a descendant of or diverges from the
  PR head, or when the PR head commit is unavailable locally. Never use `-D` for a branch that is
  merely closed, named like a feature, or believed to be merged.
- **Closed-without-merge exception**: `git branch -D` only after the user names the branch in
  the step 5 confirmation, the exact local tip equals the closed PR head, and any attached
  worktree is clean and idle. A confirmation never authorizes force-removing a worktree with Unknown blockers; **Blocked removal** in the `worktree` skill owns the classification.
- **Review-worktree confirmation**: may remove every clean, idle worktree whose HEAD exactly
  matches a remote PR head, including detached worktrees and multiple worktrees for one PR. It
  never authorizes deleting local branch refs unless those branches separately qualify.
- A merged PR proves the exact PR head and every commit reachable from that head. For a local tip
  that differs from the PR head, run `git merge-base --is-ancestor <local-tip> <pr-head>`. If it
  succeeds, every local commit was in the PR and the branch may qualify under the merged-PR-
  contained-history exception. If it fails, retain the branch because it may contain new or
  diverged work.
- Do not infer that a branch is merged from its name, a closed-but-unmerged pull request, or a
  stale local ref.
- Retain a branch used by an open PR even if an older PR for that branch was merged.
  The review-worktree confirmation can remove only a qualifying worktree, not that ref.
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
  --json number,title,headRefName,headRefOid,state,mergedAt,baseRefName,url

# GitLab (any host; prefix with GITLAB_HOST=<host> when self-hosted)
glab api --paginate "projects/<url-encoded-project-path>/merge_requests?state=all&per_page=100"
```

GitLab fields map onto the same checks: `source_branch` → `headRefName`, `sha` → `headRefOid`
(the MR head), `state` (`merged`/`closed`/`opened`) with `merged_at` → `state`/`mergedAt`,
`target_branch` → `baseRefName`, `web_url` → `url`.

If the GitHub list reaches its limit, increase it until the result is complete.
Check live open-PR state for each candidate before deletion; a truncated history
cannot prove that a branch has no open PR. Match source repository as well as branch
name when forks make the identity ambiguous; fetch PR detail when needed.

For a local branch to qualify from PR evidence, all of these must be true:

- state is merged;
- a merged timestamp is present;
- the base/target branch is the selected target;
- the head/source branch name matches the local branch name;
- the PR head commit is available locally; and
- the local branch tip either exactly equals the PR head SHA or is an ancestor of it, verified with:
  `git merge-base --is-ancestor <local-tip> <pr-head>`.

If the local tip is an ancestor of the PR head, report that the merged PR contains the complete
local commit history. It is eligible for cleanup under the merged-PR-contained-history exception,
subject to cleanliness, idleness, protection, and branch recheck rules. If the ancestry check
fails, retain it and explain that the local history is newer or diverged from the merged PR.

#### Closed without merge

Classify a PR as closed-without-merge only when its state is closed and it has no merged
timestamp; open PRs and merged PRs never fall in this category. These branches are never part of
ordinary merged cleanup and are never removed in step 6 without the confirmation collected in
step 5. Record every local branch whose name matches such a PR's source branch, and every branch
or worktree whose tip exactly equals such a PR's head, with the PR number, title, URL, head SHA,
close date, and closing comment when the CLI exposes one. Step 5 assesses them with the other
retained candidates and asks one question for all of them.

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

A worktree is removable only when its category has evidence — local ancestry in the
selected target, a merged PR whose head contains every local commit, a user-confirmed
exact closed-PR head, or a user-confirmed review match — AND every safety rule passes.
A local branch without a worktree can qualify through local ancestry, merged-PR
evidence, or a user-confirmed exact closed-without-merge head. Current, target,
open-PR, and otherwise protected branches remain protected in every category.

Before mutating anything, show a compact table with `remove`, `keep`, and `reason` for every
candidate. Every `keep` row then goes through step 5. If the user asked for a dry run, stop after
the step 5 report.

### 5. Assess retained candidates

For every branch and worktree kept in step 4, including every closed-without-merge match from
step 3, decide whether the outstanding work is **still relevant**, **superseded**, **no longer
useful**, or **unknown**. This step reads only. Skip the default branch, the current branch, and
branches with an open PR; report those as still relevant with the PR URL and stop there.

Collect this evidence per branch, from the checkout that has the target:

```sh
git merge-base <target> <branch>
git log -1 --format='%h %ci %an' <branch>
git for-each-ref --format='%(refname:short) %(upstream:short) %(upstream:track)' refs/heads/<branch>
git cherry -v <target> <branch>
git diff --stat <target>...<branch>
git merge-tree --write-tree --messages <target> <branch>
git log --oneline <merge-base>..<target> -- <files changed by the branch>
```

Read the evidence as follows:

- `git cherry` marks a commit with `-` when its individual patch already exists
  in the target under another commit, for example after a cherry-pick. A squash
  of several commits can contain all branch changes without matching those
  individual patch IDs; use the merged-PR evidence from step 3 for that case.
- `git diff <target>...<branch>` empty means the branch changes nothing against the target.
- `git merge-tree` reports conflicts when the same lines changed in the target since the merge
  base. Conflicts plus later target commits in the same files suggest the work was redone.
- `[gone]` in the upstream track means the remote branch was deleted. Read it as "someone
  finished or abandoned this on the remote", not as proof either way.
- Commit age is a weak signal on its own. Report it; do not classify on age alone.

When a forge CLI is authenticated, add forge evidence:

```sh
# GitHub
gh pr list --state all --search "<branch>" --json number,title,state,url,headRefName,body
gh pr list --state merged --base <target> --search "<ticket-key>" --json number,title,url

# GitLab (any host; prefix with GITLAB_HOST=<host> when self-hosted)
glab mr list --all --source-branch <branch> --output json
glab mr list --all --search "<branch>" --output json
glab mr list --merged --target-branch <target> --search "<ticket-key>" --output json
```

GitLab fields map as in step 3; `description` stands in for `body`.

Look for a merged PR whose title, body, or head name references the branch or its ticket key, or
uses words such as "supersedes", "replaces", or "reland". For a closed-without-merge PR, read its
closing comment and any linked PR: "superseded by #N" or "moved to #N" with #N merged is
superseded; "not needed", "won't do", or "duplicate" is no longer useful; a close with no
explanation is evidence only when combined with the local checks below. A ticket key is any `[A-Z]+-[0-9]+`
token in the branch name or its commit subjects. When a Jira or GitLab issue tool is available,
fetch the ticket and record its status; `Done`, `Closed`, or `Won't Do` with no open PR for the
branch is evidence for no longer useful.

Assign one verdict per branch:

- **Superseded**: every unique commit is patch-equivalent in the target, or the three-dot diff is
  empty, or a merged PR explicitly replaces this branch and the target already covers the files it
  touched.
- **No longer useful**: the work still differs from the target, but the ticket is closed, the
  remote branch is gone, no PR references it, and the branch has had no commit since the target
  changed the same files. A closed-without-merge PR whose head equals the local tip, or that the
  local tip is an ancestor of, counts as the PR referencing it and closing it; report the PR URL.
  State each condition that holds.
- **Still relevant**: unique changes remain, the ticket is open or unknown, and nothing in the
  target replaces them. Include recent commits and any open PR.
- **Unknown**: forge, ticket, or merge-tree evidence was unavailable or contradictory. Say which.

Show a table with `branch`, `tip`, `last commit`, `upstream`, `pr`, `verdict`, `recommend`, and
`evidence`. `pr` holds the closed-without-merge or superseding PR number and state, or `-`.
`recommend` is `remove after confirmation` only for superseded or no-longer-useful branches whose
worktree, if any, is clean and idle; otherwise `keep`. Quote the exact commands whose output backs
each verdict. Then ask:

> These retained branches look superseded or no longer useful, including branches whose PR was
> closed without merging. Name any you want removed with `git branch -D`; I will record each tip
> SHA for recovery first. Anything you do not name stays. This does not remove remote branches or
> discard dirty or active work.

Wait for the answer. Only branches the user names may be removed, one at a time, after a fresh
tip recheck. A branch whose tip exactly equals a closed PR head is removed under the
closed-without-merge exception; every other named branch is removed under the relevance safety
rule. Report which rule backed each deletion.

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

Before any `-D`, re-verify the matching exception's exact-tip and state conditions immediately
before the command, including the ancestry check for contained-history cleanup, and report which
exception — exact squash-merged PR head, merged-PR-contained history, or user-confirmed
closed-without-merge head, or user-confirmed relevance removal — backed the forced local ref
deletion. Relevance removal requires the named-branch confirmation and recorded recovery tip
from step 5; it is not merge evidence. If the target branch is not checked out anywhere, retain
candidates requiring `-d` rather than switching a user's checkout; an eligible confirmed
PR-head or relevance deletion may use `-D` from the current checkout instead.

After each successful mutation, refresh and show:

```sh
git worktree list --porcelain
git branch --list
git worktree prune --dry-run
```

Use `git worktree prune` only to remove stale administrative records after confirming that no
valid worktree path is missing. Do not overlap removal commands; wait for each command to finish.

### 7. Report the final state

End with:

- every removed worktree and local branch;
- every removed review worktree grouped by PR, including duplicate paths for the same PR;
- every retained candidate and the reason it was retained;
- the step 5 verdict for every retained branch, with the evidence behind it and the tip SHA of
  every branch removed on relevance grounds;
- the final worktree and branch inventory;
- confirmation that remote branches were not changed;
- any inconclusive checks, such as unavailable forge or process evidence.

Do not claim that all merged work is clean if any candidate was retained or any check was
inconclusive. Do not present a relevance verdict as proof of a merge.
