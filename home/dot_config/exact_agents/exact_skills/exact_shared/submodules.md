# Shared submodule flow — owned submodules ship and land with the branch

Shared by `ship` and `land`. A superproject gitlink change is incomplete
without its submodule commits. For owned submodules, both skills carry the
submodule branch through the same steps. `land` reads
[land/references/submodules.md](../land/references/submodules.md) for its
**Land** steps.

## Facts

For every entry in `.gitmodules`, establish:

- `SUB_PATH` — the submodule path. `SUB_NAME` — its `.gitmodules` name.
- `SUB_CHANGED` — true when the gitlink differs between `COMMIT_BASE` and
  `HEAD`, staged or unstaged gitlink changes exist, or the initialized submodule
  has authorized uncommitted work. Check the committed diff with
  `git diff --submodule=short COMMIT_BASE HEAD -- <SUB_PATH>`, staged and
  unstaged diffs for `SUB_PATH`, and the submodule's
  `git status --porcelain --ignore-submodules=none`. Do not ignore dirty
  submodule work merely because the committed gitlink is unchanged. Refresh
  these facts after the commit gate. Submodules with `SUB_CHANGED` false are
  ignored by both skills.
- `SUB_OWNED` — true when the submodule URL
  (`git config -f .gitmodules submodule.<SUB_NAME>.url`) is relative
  (`./` or `../`), or when it shares the host and the first path segment
  (group, organization, or user) with `git remote get-url origin`. A repo
  `AGENTS.md` may declare a submodule owned or foreign; that declaration wins.
- `SUB_BRANCH` — the branch that holds the submodule commits: `BRANCH`, the
  same name as the superproject branch. Create it at the submodule HEAD when
  the submodule is detached (`git -C <SUB_PATH> switch -c <BRANCH>`); ask when
  a different branch is already checked out there.
- `SUB_TARGET` — the submodule's default branch, resolved inside `<SUB_PATH>`:
  for `ship`, **Remote default name**; for `land`, **Local target name**, both
  in [default-branch.md](default-branch.md). `land` reads it from the main
  checkout's clone of the submodule (`<MAIN_WT>/<SUB_PATH>`), never from the
  worktree's clone.

A changed submodule that is not owned stops the skill: the recorded commit
must already exist on the submodule's remote (`git -C <SUB_PATH> branch -r
--contains HEAD` prints a branch). If it does not, report the submodule path
and commit ID and stop; never push to a foreign remote.

## Commit gate

The gate covers each changed submodule first, then the superproject:

1. In `<SUB_PATH>`, run the `commit` skill for authorized changes, then
   require `git -C <SUB_PATH> status --porcelain --ignore-submodules=none` to
   print nothing.
2. The superproject gitlink must equal the submodule HEAD: `git submodule
   status` shows no `+` for `SUB_PATH`. A `+` means the submodule moved after
   the last superproject commit; stage `SUB_PATH` and commit the bump through
   the `commit` skill: header `<type>(<SUB_NAME>): bump to <short>`, with the
   submodule commit subject in the body. Take `<type>` from the `commit`
   skill's **Choosing the type** procedure for the submodule change: `deps`
   for a third-party bump, else the type of the change the bump brings in.
3. Then the superproject gate from [git-flow.md](git-flow.md).

## Ship

Ship submodules first so the superproject never points at a missing commit.

1. Push each changed owned submodule from its worktree clone:
   `git -C <SUB_PATH> push -u origin <SUB_BRANCH>`.
   Push and force rules are `ship` step 2's; also never force-push `SUB_TARGET`.
2. Open or update the submodule MR/PR against `SUB_TARGET` with the same
   planned title as the superproject MR/PR and a one-line description of the
   change. Link the superproject MR/PR when it already exists. Check for an
   existing submodule MR/PR first, as `ship` step 3 does.
3. Push the superproject with `--recurse-submodules=check`. A refusal here
   means step 1 did not reach the remote; do not retry without the flag.
   Do not use `on-demand`: it fails on a detached submodule HEAD.
4. After `ship` step 3 creates or updates the superproject MR/PR, add each
   submodule MR/PR link to its description and the superproject link to each
   submodule description. Report both. State the merge order: merge the
   submodule MR/PR first. When the
   submodule project squash-merges, the gitlink then points at a commit that
   is no longer on `SUB_TARGET`; the superproject needs a bump commit to the
   squashed commit before its own merge. Say so in the report when the
   intended merge method is squash. Read the repository's merge policy and
   the forge's project or repository settings; PR/MR detail alone does not
   establish the intended method. If the method is unknown, report the
   conditional squash warning.
