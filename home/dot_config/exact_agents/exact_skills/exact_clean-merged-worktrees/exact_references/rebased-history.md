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
- Check `git cat-file -e <pr-head>^{commit}`. A normal branch fetch can miss
  a merged PR head after its source branch was deleted. Fetch that exact PR
  head through the forge's PR ref, then verify it matches the recorded live SHA.
  For GitHub: `git fetch origin refs/pull/<number>/head`. Do not create or
  overwrite a local branch merely to fetch evidence.
- Check `git rev-parse --is-shallow-repository`. If shallow boundaries prevent
  checking the relevant history, deepen or unshallow that history before
  concluding there is no ancestry. An unresolved fetch or history error means
  unknown; retain the candidate.

## Compare patches after a rebase

Associate the branch with a verified merged PR by source repository and branch
name, or by an explicit PR reference in its name or commits. A matching title
can suggest a PR to investigate; it does not establish identity on its own.
Review aliases such as `fix/pr780-progress` need not match the PR's source
branch for relevance assessment. They still cannot use the named-source-branch
merge exceptions in `SKILL.md`.

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

The `rev-list --merges` check must also succeed with empty output before patch
equivalence alone supports a superseded verdict. Local-only merge commits can
contain unique conflict-resolution edits that both comparison tools miss.
If any are present, retain as unknown unless separate evidence, such as the
conflict-free target-tree check below, proves there is no net content to keep.
Mark the branch superseded only with a verified association and complete,
available history. Record the PR URL, both tips, commands, exit codes, and output.

A `+` entry means equivalence was not proved. It can reflect additional work,
conflict-resolution edits, or a squash of several local commits. `range-diff`
helps explain the difference; an approximate match does not authorize removal.
Absent stronger evidence, retain as still relevant or unknown.

For another check against the selected target:

```sh
git merge-tree --write-tree --messages <target-tip> <local-tip>
git rev-parse <target-tip>^{tree}
```

If the merge succeeds without conflicts and its output tree equals the target
tree, the branch adds no net content to that target. This supports a superseded
verdict. Conflicts are not proof of replacement, and a different output tree
does not prove that the remaining differences are still wanted.

## Keep the deletion rules

Report separately how many candidates qualify through exact ancestry/merged-PR
history, how many are superseded through patch or tree evidence, and how many
remain dirty, active, or unverified. Do not describe rebased merged work as
outstanding merely because its original SHA differs.

Patch equivalence and equal virtual-merge trees authorize no deletion by
themselves. Superseded branches still require the named-branch confirmation
and recorded recovery tip from `assess-retained.md`. Recheck tips, cleanliness,
process use, and open-PR protection immediately before removal.
