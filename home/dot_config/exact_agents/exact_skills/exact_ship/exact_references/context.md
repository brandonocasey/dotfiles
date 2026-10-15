## 0. Detect context (always run first)

Establish the **Facts** of [git-flow.md](../../shared/git-flow.md) using these
remote target details:

- `HOST` — from `git remote get-url origin`: `gitlab.com` → `glab`; `github.com` → `gh`;
  self-hosted GitLab → `glab` prefixed with `GITLAB_HOST=<host>`; anything else (forgejo/gitea)
  → a matching CLI if installed, else the host's REST API with a token, else plain `git push`
  and use the create-MR/PR URL the remote prints on push.
- `TICKET` — issue/ticket key (e.g. `PUBS-1234`) from the branch name or unpushed commit
  subjects. Unset if none. When commits require a key and none is found, create the
  ticket before the commit gate: read mr-ticket's conventions, then follow its step 4
  without the MR/PR URL. Step 3 then reuses that key.
- `REMOTE_DEFAULT` — resolve `origin` through **Remote default name** in
  [default-branch.md](../../shared/default-branch.md).
- `EXISTING` — find an open MR/PR for `BRANCH` before selecting its target
  (`glab mr list --source-branch <BRANCH>` / `gh pr list --head <BRANCH>`).
  Read its base branch. A failed lookup does not establish that none exists.
- `TARGET` — the user's explicit target, otherwise `EXISTING`'s base, otherwise
  the verified parent branch for dependent work, otherwise `REMOTE_DEFAULT`.
  For dependent work, read [dependent-branches.md](../../shared/dependent-branches.md).
  Preserve an existing base unless the user requests a different one. Fetch and pin
  `<TARGET>` per [default-branch.md](../../shared/default-branch.md) **Fetch and
  pin**, and record the pinned commit as `COMMIT_BASE`.

If `BRANCH` equals `REMOTE_DEFAULT` or `TARGET`, read
[default-branch-recovery.md](default-branch-recovery.md) before proceeding.

When `.gitmodules` exists, also read [submodules.md](../../shared/submodules.md) and
establish its **Facts** (`SUB_CHANGED`, `SUB_OWNED`, `SUB_BRANCH`, `SUB_TARGET`).
