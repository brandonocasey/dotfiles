# Shared submodule flow — owned submodules ship and land with the branch

Shared by the `ship` and `land` skills. A superproject branch that changes a
submodule's recorded commit (gitlink) is incomplete without the submodule
commits it points to. When the submodule is owned together with the
superproject, both skills carry the submodule branch through the same steps.

## Facts

For every entry in `.gitmodules`, establish:

- `SUB_PATH` — the submodule path. `SUB_NAME` — its `.gitmodules` name.
- `SUB_CHANGED` — true when the gitlink differs between `COMMIT_BASE` and
  `HEAD`: `git diff --submodule=short COMMIT_BASE HEAD -- <SUB_PATH>` prints a
  line. Submodules with `SUB_CHANGED` false are ignored by both skills.
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
MUST already exist on the submodule's remote (`git -C <SUB_PATH> branch -r
--contains HEAD` prints a branch). If it does not, report the submodule path
and commit ID and stop; never push to a foreign remote.

## Commit gate

The gate covers each changed submodule first, then the superproject:

1. In `<SUB_PATH>`, run the `commit` skill for authorized changes, then
   require `git -C <SUB_PATH> status --porcelain --ignore-submodules=none` to
   print nothing.
2. The superproject gitlink MUST equal the submodule HEAD: `git submodule
   status` shows no `+` for `SUB_PATH`. A `+` means the submodule moved after
   the last superproject commit; stage `SUB_PATH` and commit the bump through
   the `commit` skill (`build(<SUB_NAME>): bump to <short> <subject>`).
3. Then the superproject gate from [git-flow.md](git-flow.md).

## Ship

Order: submodule first, superproject last, so the superproject never points
at a commit the remote lacks.

1. Push each changed owned submodule from its worktree clone:
   `git -C <SUB_PATH> push -u origin <SUB_BRANCH>` (`--force-with-lease` after a
   rebase or amend, never plain `--force`, never on `SUB_TARGET`).
2. Open or update the submodule MR/PR against `SUB_TARGET` with the same
   title as the superproject MR/PR and a one-line description that links the
   superproject MR/PR. Check for an existing one first, as `ship` step 3 does.
3. Push the superproject with `--recurse-submodules=check`. A refusal here
   means step 1 did not reach the remote; do not retry without the flag.
4. Add the submodule MR/PR link to the superproject description, and report
   both. State the merge order: merge the submodule MR/PR first. When the
   submodule project squash-merges, the gitlink then points at a commit that
   is no longer on `SUB_TARGET`; the superproject needs a bump commit to the
   squashed commit before its own merge. Say so in the report when the
   project's merge method is squash (`glab mr view` / `gh pr view` show it).

## Land

Each worktree has its own submodule clone under
`.git/worktrees/<name>/modules/<SUB_NAME>`. The clone that persists is the
main checkout's, under `.git/modules/<SUB_NAME>`, so the submodule branch
lands there. The fetch below reads a local path, not a remote; it is the one
fetch `land` allows. This flow requires `MAIN_WT` to be that main checkout (the
first `worktree` entry of `git worktree list --porcelain`). If `TARGET` is
checked out in a linked worktree instead, stop and ask: that worktree's
submodule clone does not persist, so landing the submodule branch there loses it.

1. In the worktree, rebase `SUB_BRANCH` onto the main clone's `SUB_TARGET`
   commit before the superproject rebase: `git -C <SUB_PATH> rebase
   <sub-target-commit>` where the commit is
   `git -C <MAIN_WT>/<SUB_PATH> rev-parse <SUB_TARGET>`. If the rebase
   changes the submodule tip, commit the gitlink bump in the superproject
   (**Commit gate** step 2), then continue with the superproject rebase.
2. Copy the branch into the main clone:
   `git -C <MAIN_WT>/<SUB_PATH> fetch <worktree-path>/<SUB_PATH> <SUB_BRANCH>:<SUB_BRANCH>`.
   A refusal means a stale `SUB_BRANCH` exists there; stop and ask.
3. Fast-forward the submodule in the main clone, before the superproject:
   ```sh
   git -C <MAIN_WT>/<SUB_PATH> switch <SUB_TARGET>
   git -C <MAIN_WT>/<SUB_PATH> merge --ff-only <SUB_BRANCH>
   git -C <MAIN_WT>/<SUB_PATH> branch -d <SUB_BRANCH>
   ```
   The main clone MUST be clean and either on `SUB_TARGET` or detached at the
   gitlink `TARGET` records; anything else is an unexpected state: stop and
   ask. A non-fast-forward means step 1 did not take: stop and report.
4. Fast-forward the superproject (`land` step 4). Afterwards
   `git -C <MAIN_WT> submodule status` MUST show no `+` for `SUB_PATH`; the
   submodule HEAD equals the new gitlink.
5. Cleanup follows `land` step 5. The worktree's submodule clone is deleted
   with the worktree; that is safe because step 3 made the commits reachable
   from `SUB_TARGET` in the main clone, which the `worktree` skill's
   **Submodules** rule accepts as proof.
