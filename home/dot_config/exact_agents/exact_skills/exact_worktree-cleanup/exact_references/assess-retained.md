# Assess retained candidates

For every branch and worktree kept in step 4, including every closed-without-merge match from
step 3, decide whether the outstanding work is **still relevant**, **superseded**, **no longer
useful**, or **unknown**. This step changes no refs or worktree files.
`git merge-tree --write-tree` can add unreachable objects to the repository.
Skip the default branch, the current branch, and branches with an open PR.
Report those as still relevant, with the PR URL when one exists, and stop there.

When ancestry fails despite a matching merged PR, or retained work appears
completed after a rebase, read [rebased-history.md](rebased-history.md).
It separates patch or tree equivalence from permission to delete.

Collect this evidence per branch, from the checkout that has the target:

```sh
git merge-base <target> <branch>
git log -1 --format='%h %ci %an' <branch>
git for-each-ref --format='%(refname:short) %(upstream:short) %(upstream:track)' refs/heads/<branch>
git cherry -v <target> <branch>
git rev-list --merges <target>..<branch>
git diff --stat <target>...<branch>
git merge-tree --write-tree --messages <target> <branch>
git rev-parse <target>^{tree}
git log --oneline <merge-base>..<target> -- <files changed by the branch>
```

Read the evidence as follows:

- `git cherry` marks a commit with `-` when its individual patch already exists
  in the target under another commit, for example after a cherry-pick. A squash
  of several commits can contain all branch changes without matching those
  individual patch IDs; use the merged-PR evidence from step 3 for that case.
- `git cherry` omits merge commits. Patch equivalence alone is insufficient
  when `git rev-list --merges <target>..<branch>` reports local-only merges.
  Those merges can contain unique conflict-resolution edits.
- An empty three-dot diff means the branch tree matches the merge base.
  It does not compare the branch directly with the current target tree.
- `git merge-tree` reports conflicts when the same lines changed in the target since the merge
  base. Conflicts plus later target commits in the same files suggest the work was redone.
  A successful, conflict-free merge whose output tree equals the target tree
  proves that the branch adds no net content. A different tree does not.
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

- **Superseded**: all local-only non-merge patches are represented in the target
  and no local-only merge exists; or the conflict-free virtual merge equals
  the target tree; or explicit replacement evidence proves every change is covered.
  Require successful commands and complete relevant history. Errors or missing
  history mean unknown. File overlap or a matching PR title alone is insufficient.
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
