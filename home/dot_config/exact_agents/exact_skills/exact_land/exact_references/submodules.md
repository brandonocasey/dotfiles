# Land an owned submodule with the branch

Read from `SKILL.md` step 0 when `.gitmodules` exists and a submodule has
`SUB_CHANGED`. Facts and the **Commit gate** are in
[submodules.md](../../shared/submodules.md).

Each worktree has its own submodule clone under
`<git-common-dir>/worktrees/<name>/modules/<SUB_NAME>`. The clone that persists is the
main checkout's, under `<git-common-dir>/modules/<SUB_NAME>`, so the submodule branch
lands there. The fetches below read local paths, not remotes; `land` allows
both directions between these clones. This flow requires `MAIN_WT` to be
that main checkout (the first `worktree` entry of `git worktree list --porcelain`).
If `TARGET` is checked out in a linked worktree, or nowhere (a temporary
target worktree), stop and ask: that
worktree's submodule clone does not persist, so landing the submodule branch
there loses it.

1. Before changing either clone, the main clone must be clean and either
   on `SUB_TARGET` or detached at the gitlink `TARGET` records. Otherwise stop
   and ask. In the worktree clone, fetch the main clone's local target
   (`git -C <SUB_PATH> fetch <MAIN_WT>/<SUB_PATH> refs/heads/<SUB_TARGET>`) and
   pin `FETCH_HEAD` as `<sub-target-commit>` per `shared/default-branch.md`
   **Fetch and pin**; a commit ID read only in the main clone may not exist in
   the worktree clone. Rebase `SUB_BRANCH` onto that ID before the superproject
   rebase: `git -C <SUB_PATH> rebase <sub-target-commit>`.
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
   before the switch and merge. A non-fast-forward means step 1 did not take: stop and report.
4. Fast-forward the superproject (`land` step 4). Afterwards
   `git -C <MAIN_WT> submodule status` must show no `+` for `SUB_PATH`; the
   submodule HEAD equals the new gitlink.
5. Cleanup follows `land` step 5.
