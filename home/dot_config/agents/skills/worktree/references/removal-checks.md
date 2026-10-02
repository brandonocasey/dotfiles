# Removal checks

### Submodules

Git refuses to remove a worktree that holds an initialized submodule, clean or
not: `working trees containing submodules cannot be moved or removed`. Only
`--force` removes it, and `--force` deletes the submodule's git directory under
`.git/worktrees/<name>/modules/`, so a submodule commit that exists nowhere else
is lost. Before that single `--force`, prove all three points for every
initialized submodule (an entry of `git -C <worktree-path> submodule status
--recursive` without a leading `-`):

1. **Recorded**: the entry has no `+` or `U` prefix. `+` means the checked-out
   commit differs from the gitlink the superproject records, which is an
   uncommitted change; `U` is a merge conflict. Treat either like a modified
   tracked file.
2. **Clean**:
   `git -C <worktree-path>/<sub-path> status --porcelain --ignore-submodules=none`
   prints nothing.
3. **Preserved**: the commit exists outside this worktree's clone. Either
   `git -C <worktree-path>/<sub-path> fetch --quiet` and then
   `git -C <worktree-path>/<sub-path> branch -r --contains HEAD` prints a
   remote branch, or the main checkout's clone holds it:
   `git -C <main-checkout>/<sub-path> merge-base --is-ancestor <commit> <sub-target>`
   succeeds (the `land` path in `shared/submodules.md`). Neither: push the
   commit to the submodule's remote first, or keep the worktree and report the
   submodule path and commit ID.

When all three hold for every submodule and no other blocker exists, remove
with `--force` once, as in **Blocked removal** step 5. Uninitialized
submodules (`-` prefix, empty directory) never block removal.

### Blocked removal

`git worktree remove` refuses a tree with modified tracked files or untracked
files. Ignored files never block it. Never commit, stash, or discard to clear
the block. Classify every blocker first; `--force` is allowed only when every
blocker is either already saved in the repository or disposable, and every
initialized submodule passes **Submodules**.

1. List the blockers. `--ignore-submodules=none` is required: a
   `diff.ignoreSubmodules` setting or a `.gitmodules` `ignore` entry hides
   dirty submodules otherwise.
   ```sh
   git -C <worktree-path> status --porcelain --untracked-files=all \
     --ignore-submodules=none
   ```
2. Classify each path:
   - **Saved**: the file's current content already exists in the repository
     (a commit on any branch, or a stash). Evidence: this prints a commit:
     ```sh
     git -C <worktree-path> log --all -n 1 --oneline \
       --find-object=$(git -C <worktree-path> hash-object <file>)
     ```
   - **Disposable**: untracked (`??`) and generated: build or test output
     (`dist/`, `build/`, `coverage/`, `*.log`, `*.tsbuildinfo`, `.DS_Store`),
     dependency directories (`node_modules/`, `.venv/`, `vendor/`, `target/`),
     editor swap files. Source files, notes, `.env*`, and credentials are
     never disposable, even when untracked.
   - **Unknown**: anything else.
3. If any blocker is Unknown, retain the worktree, show a table with
   `path`, `class`, `evidence`, and ask.
4. Otherwise back up every Disposable file except dependency directories to
   the backups directory (AGENTS.md, **Directories**), keeping the relative
   paths. Saved files need no copy; record the commit that holds them.
5. Remove with a single `--force`, from outside the worktree:
   ```sh
   git -C <main-checkout> worktree remove --force <worktree-path>
   ```
   Never pass `--force` twice. A locked worktree (`locked` in
   `git worktree list --porcelain`) is never removed; report it.
6. Report each blocker with its class, evidence, and backup path.

Batch cleanup runs only when the user invokes `clean-merged-worktrees`. Do not
start it because a worktree task ended.
