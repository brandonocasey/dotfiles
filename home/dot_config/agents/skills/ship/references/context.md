## 0. Detect context (always run first)

Read [git-flow.md](../../shared/git-flow.md), resolved against this file's path, not the
user's repo. Establish its **Facts** using these remote target details:

- `HOST` — from `git remote get-url origin`: `gitlab.com` → `glab`; `github.com` → `gh`;
  self-hosted GitLab → `glab` prefixed with `GITLAB_HOST=<host>`; anything else (forgejo/gitea)
  → a matching CLI if installed, else the host's REST API with a token, else plain `git push`
  and use the create-MR/PR URL the remote prints on push.
- `TICKET` — issue/ticket key (e.g. `PUBS-1234`) from the branch name or unpushed commit
  subjects. Unset if none. When the repo requires one, settle it per step 3 before the
  commit gate.
- `REMOTE_DEFAULT` — resolve `origin` through **Remote default name** in
  [default-branch.md](../../shared/default-branch.md). Never use a cached
  `origin/HEAD` to decide whether a branch is safe to push.
- `EXISTING` — find an open MR/PR for `BRANCH` before selecting its target
  (`glab mr list --source-branch <BRANCH>` / `gh pr list --head <BRANCH>`).
  Read its base branch. A failed lookup does not establish that none exists.
- `TARGET` — the user's explicit target, otherwise `EXISTING`'s base, otherwise
  the verified parent branch for dependent work, otherwise `REMOTE_DEFAULT`.
  For dependent work, read [dependent-branches.md](../../shared/dependent-branches.md).
  Preserve an existing base unless the user requests a different one. Fetch it with
  `git fetch origin refs/heads/<TARGET>` and immediately record
  `git rev-parse FETCH_HEAD` as `COMMIT_BASE`. Do not require a local target branch
  or assume that the fetch updated `origin/<TARGET>` under a restricted refspec.

If `BRANCH` equals `REMOTE_DEFAULT` or `TARGET`, read
[default-branch-recovery.md](default-branch-recovery.md) before proceeding.

When `.gitmodules` exists, also read [submodules.md](../../shared/submodules.md) and
establish its **Facts** (`SUB_CHANGED`, `SUB_OWNED`, `SUB_BRANCH`, `SUB_TARGET`). A changed
owned submodule ships together with `BRANCH`: same branch name, its own MR/PR, pushed first.
