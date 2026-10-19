# Diagnose rebased or squash-merged work

Use this when a local tip fails ancestry checks despite a matching merged PR,
or many retained worktrees appear to contain completed work. Keep merge
eligibility separate from relevance: equivalent patches do not prove that the
original commits were merged.

## Check the evidence first

- Record the local tip, selected target tip, and live PR head SHA. Verify the
  PR's source repository, state, merged timestamp, and base/target branch.
- `git merge-base --is-ancestor` returns 0 for ancestry and 1 for no ancestry.
  Other exit codes are errors, not divergence. Resolve missing objects first.
- Check `git cat-file -e <pr-head>^{commit}`. If the PR head is missing, fetch it
  per [forge-edge-cases.md](forge-edge-cases.md) **PR head missing locally**.
- Check `git rev-parse --is-shallow-repository`. If shallow boundaries prevent
  checking the relevant history, deepen or unshallow that history before
  concluding there is no ancestry. An unresolved fetch or history error means
  unknown; retain the candidate.

## Compare patches after a rebase

Associate the branch with a verified merged PR by source repository and branch
name, or by an explicit PR reference in its name or commits. A matching title
can suggest a PR to investigate; it does not establish identity on its own.
Review aliases such as `fix/pr780-progress` need not match the PR's source
branch for relevance assessment. They still cannot count as merged under `agt cleanup --only worktrees`, which
requires the PR's source branch to be the local branch.

Run against the recorded commits:

```sh
git merge-base <local-tip> <pr-head>
git cherry -v <pr-head> <local-tip>
git rev-list --merges <pr-head>..<local-tip>
git range-diff <merge-base>..<local-tip> <merge-base>..<pr-head>
```

`git cherry` checks local-only non-merge commits; `range-diff` also omits merge
commits. A successful result containing only `-` entries means those individual
patches are represented in the merged PR head. A successful empty result means
no local-only non-merge commits remain; recheck ancestry before claiming
contained history.

The `rev-list --merges` check must also succeed with empty output before patch equivalence
supports a superseded verdict (see [assess-retained.md](assess-retained.md)); otherwise retain
as unknown. Mark the branch superseded only with a verified association and complete, available
history. Record the PR URL, both tips, commands, exit codes, and output.

A `+` entry means equivalence was not proved. It can reflect additional work,
conflict-resolution edits, or a squash of several local commits. `range-diff`
helps explain the difference; an approximate match does not authorize removal.
Absent stronger evidence, retain as still relevant or unknown.

For the virtual-merge tree check against the selected target, follow
[assess-retained.md](assess-retained.md).

## Keep the deletion rules

Report separately how many candidates qualify through exact ancestry/merged-PR
history, how many are superseded through patch or tree evidence, and how many
remain dirty, active, or unverified. Do not describe rebased merged work as
outstanding merely because its original SHA differs.

Patch equivalence and equal virtual-merge trees authorize no deletion; removal
rules are in [assess-retained.md](assess-retained.md).
