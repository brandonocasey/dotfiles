# Default branch identity and base selection

Use this file when a workflow needs a default branch name or a starting commit.
These decisions are separate. Base selection MUST NOT move a local branch,
change a checkout, merge histories, or push.

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
4. If no candidate contains all the others, the defaults diverge. Show the refs,
   IDs, and unique commits, then ask which base to use. Commit timestamps do not
   establish that one history contains another. An ancestry command error is
   not proof of divergence: resolve missing or shallow history first, or report
   that it could not be checked.

Report the selected base ref and commit. Do not claim that a cached remote ref
is current. If the user requires offline or local-only work, use local evidence
within that scope and disclose that remote freshness was not checked.
