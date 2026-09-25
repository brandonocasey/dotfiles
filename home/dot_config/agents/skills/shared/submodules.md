# Shared submodule flow — owned submodules ship and land with the branch

Shared by `ship` and `land`. A superproject gitlink change is incomplete
without its submodule commits. For owned submodules, both skills carry the
submodule branch through the same steps.

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
   the `commit` skill: header `build(<SUB_NAME>): bump to <short>`, with the
   submodule commit subject in the body.
3. Then the superproject gate from [git-flow.md](git-flow.md).

## Ship

Ship submodules first so the superproject never points at a missing commit.

1. Push each changed owned submodule from its worktree clone:
   `git -C <SUB_PATH> push -u origin <SUB_BRANCH>` (`--force-with-lease` after a
   rebase or amend, never plain `--force`, never on `SUB_TARGET`).
2. Open or update the submodule MR/PR against `SUB_TARGET` with the same
   planned title as the superproject MR/PR and a one-line description of the
   change. Link the superproject MR/PR when it already exists. Check for an
   existing submodule MR/PR first, as `ship` step 3 does.
3. Push the superproject with `--recurse-submodules=check`. A refusal here
   means step 1 did not reach the remote; do not retry without the flag.
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

## Land

Each worktree has its own submodule clone under
`.git/worktrees/<name>/modules/<SUB_NAME>`. The clone that persists is the
main checkout's, under `.git/modules/<SUB_NAME>`, so the submodule branch
lands there. The fetches below read local paths, not remotes; `land` allows
both directions between these clones. This flow requires `MAIN_WT` to be
that main checkout (the
first `worktree` entry of `git worktree list --porcelain`). If `TARGET` is
checked out in a linked worktree instead, stop and ask: that worktree's
submodule clone does not persist, so landing the submodule branch there loses it.

1. Before changing either clone, the main clone must be clean and either
   on `SUB_TARGET` or detached at the gitlink `TARGET` records. Otherwise stop
   and ask. In the worktree clone, fetch the main clone's local target:
   `git -C <SUB_PATH> fetch <MAIN_WT>/<SUB_PATH> refs/heads/<SUB_TARGET>`.
   Immediately record `git -C <SUB_PATH> rev-parse FETCH_HEAD` as
   `<sub-target-commit>`; a commit ID read only in the main clone may not
   exist in the worktree clone. Rebase `SUB_BRANCH` onto that ID before the
   superproject rebase: `git -C <SUB_PATH> rebase <sub-target-commit>`.
   If the rebase changes the submodule tip, commit the gitlink bump in the
   superproject (**Commit gate** step 2), then continue with the superproject
   rebase.
2. Copy the branch into the main clone:
   `git -C <MAIN_WT>/<SUB_PATH> fetch <worktree-path>/<SUB_PATH> <SUB_BRANCH>:<SUB_BRANCH>`.
   This fetch must not force-update an existing branch. A refusal can mean
   divergent branch history or another fetch error; retain both clones and
   report the actual error before proceeding.
3. Fast-forward the submodule in the main clone, before the superproject:
   ```sh
   git -C <MAIN_WT>/<SUB_PATH> switch <SUB_TARGET>
   git -C <MAIN_WT>/<SUB_PATH> merge --ff-only <SUB_BRANCH>
   git -C <MAIN_WT>/<SUB_PATH> branch --unset-upstream <SUB_BRANCH> || true
   git -C <MAIN_WT>/<SUB_PATH> branch -d <SUB_BRANCH>
   ```
   Recheck the clean-tree and checkout requirements from step 1 immediately
   before the switch and merge. Unset the landed branch's upstream before
   deleting it so `branch -d` checks against `SUB_TARGET`, as `land` cleanup
   requires. A non-fast-forward means step 1 did not take: stop and report.
4. Fast-forward the superproject (`land` step 4). Afterwards
   `git -C <MAIN_WT> submodule status` must show no `+` for `SUB_PATH`; the
   submodule HEAD equals the new gitlink.
5. Cleanup follows `land` step 5. The worktree's submodule clone is deleted
   with the worktree; that is safe because step 3 made the commits reachable
   from `SUB_TARGET` in the main clone, which the `worktree` skill's
   **Submodules** rule accepts as proof.
