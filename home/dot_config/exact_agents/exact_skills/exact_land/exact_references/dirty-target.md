# Dirty target: stash and restore around the fast-forward

Read when `TARGET_DIRTY` (the target tree has local uncommitted work) at
`SKILL.md` step 4. Stash first so the fast-forward lands on a clean tree, then
restore afterward.

Run the stash in `MAIN_WT`, the worktree that holds `TARGET`. Use a labelled,
include-untracked stash with a unique `<stash-label>` for this run, so it is
identifiable and nothing is left behind:

```sh
git -C <MAIN_WT> stash push --include-untracked -m <stash-label>
```

Verify the entry has this run's label and record its commit ID, not its stack
position. If `stash push` reports "No local changes to save", skip restoration.

If `--ff-only` fails, report the stash and how to restore it.

## Restore

After a successful ff, only if this run created a stash, apply the recorded
commit ID so another stash cannot change which work is restored:

```sh
git -C <MAIN_WT> stash apply --index <stash-commit>
```

If that commit cannot be identified as this run's stash, stop and report.

- Clean apply: verify the restored files and staging state against the recorded
  pre-stash status, then find the entry by commit ID in
  `git stash list --format='%gd %H'` and drop only that matching entry. Recheck
  the ref's commit immediately before dropping it; retain it on any mismatch.
- **Conflicts on apply** (the landed commits touched the same lines as the
  stashed local work): resolve them. For each conflicted file, read both sides,
  reconcile by intent (the landed change is now the base; reapply the local
  edit on top so neither is lost — never just delete a side), then
  `git -C <MAIN_WT> add <file>`. When all are resolved, check the restored work
  and drop only the entry matching the recorded commit ID as above. Do not
  create a commit — the restored changes stay as uncommitted local work. If a
  conflict is ambiguous, stop and ask; the stash is intact.
