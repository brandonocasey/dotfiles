# Default branch identity and base selection

Use this file when a workflow needs a default branch name or a starting commit.
These decisions are separate. Base selection must not change a checkout's
branch, merge histories, or push. It moves a local branch only through the
fast-forward in **Newest default base** step 5.

## Local target name

Use the user's explicit target when given. Otherwise use the first existing
local branch in this order: the branch named by `refs/remotes/origin/HEAD`,
`main`, then `master`. Verify each ref with `git show-ref --verify`.
Otherwise, check the default names of other remotes from their available
`refs/remotes/<remote>/HEAD` refs. Use a matching local branch only if the name
is unambiguous; otherwise ask which local target to use. Do not invent `master`.

This lookup is local and performs no fetch.

## Remote default name

Resolve a remote's live default name with
`git ls-remote --symref <remote> HEAD`. If the server does not advertise a
symbolic HEAD, use its forge's default-branch metadata or ask. A cached
`refs/remotes/<remote>/HEAD` or the newest feature branch is not a live default
lookup. Report lookup failures and ask before using stale data.

## Newest default base

Use this for new branches and default-based review comparisons unless the user
supplied a base. Do not recreate or rebase existing branches or PR/MR heads.

1. List every configured remote with `git remote`. For each remote, use
   **Remote default name** above to resolve its live default. Fetch that
   branch with `git fetch <remote> refs/heads/<default>`, then immediately
   record `git rev-parse FETCH_HEAD`, the remote, and the branch name before
   another fetch overwrites `FETCH_HEAD`. This also works with restricted fetch
   refspecs.
2. Add the local target, if one resolves, and existing local branches with the
   verified remote-default names. A missing local target is not a blocker when
   remote candidates exist; do not prompt just for this optional lookup.
   Record exact commit IDs. A repository without remotes uses its verified
   local default. If no candidate resolves,
   ask for a base. If a remote lookup or fetch fails, retry when appropriate;
   otherwise report the failure and ask before excluding it or using stale data.
3. Compare the recorded commits with
   `git merge-base --is-ancestor <candidate> <other>`. Choose a commit only when
   every candidate is an ancestor of it. Equal commits are one candidate;
   prefer the local ref for the report when tied. Use the recorded commit ID
   as the worktree start point so a ref moving later cannot change the choice.
4. If no candidate contains all the others, the defaults diverge. Do not ask.
   Use the fetched default of `origin` as the base. Report each other
   candidate's unique commits with
   `git log --oneline <base-commit>..<candidate>`. Ask only when no `origin`
   remote exists and the remote defaults diverge. Commit timestamps do not
   establish that one history contains another. An ancestry command error is
   not proof of divergence: resolve missing or shallow history first, or report
   that it could not be checked.
5. Fast-forward the local target after step 3 or 4 selects a base. All of these
   conditions must be true, or skip this step:
   - The base is the commit fetched from the target's upstream remote
     (`git config branch.<target>.remote`). A commit from another remote,
     such as `upstream` in a fork, would make the target look ahead of its
     upstream.
   - The local target is a strict ancestor of the base.
   - `git diff --raw <target> <base-commit>` shows no `160000` mode. A merge
     does not update submodule checkouts, so a changed gitlink leaves the
     checkout dirty.

   Never create a merge commit, rebase, or reset:
   - Target checked out in a worktree (see `git worktree list --porcelain`)
     with an empty
     `git -C <that-worktree> status --porcelain --ignore-submodules=none`:
     run `git -C <that-worktree> merge --ff-only <base-commit>`.
   - Target checked out nowhere: run
     `git fetch . <base-commit>:refs/heads/<target>` from any checkout of the
     repository. Without `+`, Git refuses a non-fast-forward update.
   - Target checked out in a dirty worktree, or the command fails: skip the
     fast-forward and report why. The base choice does not change.

Report the selected base ref and commit, and any fast-forward or skip. Do not
claim that a cached remote ref is current. If the user requires offline or
local-only work, use local evidence within that scope and disclose that remote
freshness was not checked.
