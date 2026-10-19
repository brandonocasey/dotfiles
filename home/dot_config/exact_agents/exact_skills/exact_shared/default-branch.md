# Default branch identity and base selection

Use when a workflow needs a default branch name or starting commit.

## Local target name

Use the user's explicit target when given. Otherwise use the first existing
local branch in this order: the branch named by `refs/remotes/origin/HEAD`,
`main`, then `master`. Verify each ref with `git show-ref --verify`.
Otherwise, check the default names of other remotes from their available
`refs/remotes/<remote>/HEAD` refs. Use a matching local branch only if the name
is unambiguous; otherwise ask which local target to use. Do not invent `master`.

## Remote default name

Resolve a remote's live default name with
`git ls-remote --symref <remote> HEAD`. If the server does not advertise a
symbolic HEAD, use its forge's default-branch metadata or ask. A cached
`refs/remotes/<remote>/HEAD` or the newest feature branch is not a live default
lookup. Report lookup failures and ask before using stale data.

## Fetch and pin

Fetch `refs/heads/<branch>` from the remote (`git fetch <remote>
refs/heads/<branch>`), then immediately record `git rev-parse FETCH_HEAD` with
the remote and branch name, before another fetch overwrites `FETCH_HEAD`. Use
the recorded ID, not a ref name: a restricted fetch refspec may leave
`origin/<branch>` absent.

## Newest default base

Use this for new branches and default-based review comparisons unless the user
supplied a base. Do not recreate or rebase existing branches or PR/MR heads.

1. List every configured remote with `git remote`. For each remote, use
   **Remote default name** above to resolve its live default. Fetch and
   record it per **Fetch and pin**.
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

After step 3 or 4 selects a base for a new branch, fast-forward the local target as
[ff-local-target.md](ff-local-target.md) allows; a skip is a warning in the final report.
A base for a review comparison leaves the local target alone: reviews only read.

Report the selected base ref and commit, and any fast-forward or skip. Do not
claim that a cached remote ref is current. If the user requires offline or
local-only work, use local evidence within that scope and disclose that remote
freshness was not checked.
