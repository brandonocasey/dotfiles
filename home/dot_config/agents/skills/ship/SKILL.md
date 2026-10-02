---
name: ship
description: >
  Commit, push, and open or update a GitHub PR or GitLab MR. Use for ship or
  PR/MR requests, or when the Git rules authorize a push. On GitHub, --merge
  continues through merge.
---

Ship the current branch: push it, open or update the MR/PR, and report. When
the argument names a local branch, run every step from that branch's worktree.
Create one with the `worktree` skill if none exists. Other argument text is a
task to finish first. Parse `--merge` as an option, not a branch or task name.
Ordinary shipping ends after the push and MR/PR update.
With `--merge`, read [merge.md](references/merge.md) before mutations to check
platform support and scope. Continue that workflow after shipping.

When a `session-resume` record exists for the task, read it before the context
check. Retain its recorded authorization only within its exact provenance and
scope. The record cannot grant push authority. Reuse checks only when their code
revision, inputs, and environment match this run.

Start only with push authorization under the AGENTS.md Git rules. Without it,
ask one question and stop. With it, run every step yourself. Never tell the
user to type `/ship`.

## 0. Detect context (always run first)

Read [git-flow.md](../shared/git-flow.md), resolved against this file's path, not the
user's repo. Establish its **Facts** using these remote target details:

- `HOST` — from `git remote get-url origin`: `gitlab.com` → `glab`; `github.com` → `gh`;
  self-hosted GitLab → `glab` prefixed with `GITLAB_HOST=<host>`; anything else (forgejo/gitea)
  → a matching CLI if installed, else the host's REST API with a token, else plain `git push`
  and use the create-MR/PR URL the remote prints on push.
- `TICKET` — issue/ticket key (e.g. `PUBS-1234`) from the branch name or unpushed commit
  subjects. Unset if none.
- `REMOTE_DEFAULT` — resolve `origin` through **Remote default name** in
  [default-branch.md](../shared/default-branch.md). Never use a cached
  `origin/HEAD` to decide whether a branch is safe to push.
- `EXISTING` — find an open MR/PR for `BRANCH` before selecting its target
  (`glab mr list --source-branch <BRANCH>` / `gh pr list --head <BRANCH>`).
  Read its base branch. A failed lookup does not establish that none exists.
- `TARGET` — the user's explicit target, otherwise `EXISTING`'s base, otherwise
  the verified parent branch for dependent work, otherwise `REMOTE_DEFAULT`.
  For dependent work, read [dependent-branches.md](../shared/dependent-branches.md).
  Preserve an existing base unless the user requests a different one. Fetch it with
  `git fetch origin refs/heads/<TARGET>` and immediately record
  `git rev-parse FETCH_HEAD` as `COMMIT_BASE`. Do not require a local target branch
  or assume that the fetch updated `origin/<TARGET>` under a restricted refspec.

**If `BRANCH` equals `REMOTE_DEFAULT` or `TARGET`**:

- Fetch `refs/heads/<BRANCH>` from `origin` and record its commit ID before
  comparing it with local `HEAD`. If local commits are ahead or histories
  diverge, ask which commits should ship on a new branch. Never guess, reset,
  or force the checked-out branch. Stop on a missing remote branch or failed fetch.
- With a dirty tree and no local-only commits, move the work onto a branch named by the repo
  convention, using the `worktree` skill's **Recover changes made in the main checkout**
  steps. Continue from inside the new worktree and refresh `BRANCH`.
- With a clean tree and no local-only commits, report that there is nothing to ship and stop.

When `.gitmodules` exists, also read [submodules.md](../shared/submodules.md) and
establish its **Facts** (`SUB_CHANGED`, `SUB_OWNED`, `SUB_BRANCH`, `SUB_TARGET`). A changed
owned submodule ships together with `BRANCH`: same branch name, its own MR/PR, pushed first.

## 1. Commit gate

Run the **Commit gate** from `shared/git-flow.md`. It owns task scope, the
clean-tree check, and the commit report against `COMMIT_BASE`. With a changed
submodule, run the **Commit gate** in `shared/submodules.md` first; it gates the
submodule and the gitlink bump before the superproject.

## 2. Push

Immediately before any push, refresh `BRANCH` and resolve the live
`REMOTE_DEFAULT` again. Stop if `BRANCH` equals it or `TARGET`.

- First push, or new commits on an already-pushed branch: `git push -u origin <BRANCH>`.
- Branch exists on the remote but histories diverged (rebase/amend since last push):
  `git push --force-with-lease origin <BRANCH>`. Never plain `--force`; never any force on
  `TARGET` or `REMOTE_DEFAULT`; never push either from this skill.
- With a changed owned submodule, follow **Ship** in `shared/submodules.md` first: push
  `SUB_BRANCH` from the submodule and open its MR/PR, then push the superproject with
  `--recurse-submodules=check`. Git refuses that push while a recorded submodule commit
  exists on no submodule remote; never retry without the flag. `on-demand` is not used:
  it fails on a detached submodule HEAD with `src refspec ... must name a ref`.
- Check that the push landed (`git status -sb` shows no ahead-count) and say so — the user
  should never have to ask "did you push?".

## 3. Open or update the MR/PR

- Refresh `EXISTING` before creation. Update it instead of creating a duplicate.
  If its base changed during this run, reread it before deciding the target.
- **Title**: the repo's commit/MR convention — read the repo's AGENTS.md / CLAUDE.md /
  CONTRIBUTING for it. Include `TICKET` when set. If the repo requires a ticket and there is
  none, ask the user for the key — never invent one.
- **Description**: 2 sentences max — what changed and the approach. Add the config/data used
  for testing when the repo convention asks for it. No product framing, no filler, no
  checklists.
- Use the recorded `TARGET`. Leave draft state alone unless asked.

## 4. Finish the requested scope

- With `--merge`, read [merge.md](references/merge.md) and finish that workflow
  before cleanup. It supports GitHub through `auto-merge-watch`.
- Honor an explicit monitoring or repair request in the current turn. Keep the
  worktree until that work ends. Without one, report the pipeline URL without waiting.
- Handle CI when the user requests it, or once for jobs that already
  failed when the `review` skill's own-work rule requires it.
  Then: pull the failing job's log (`glab ci trace <job>` / `gh run view <run-id> --log-failed`), find
  the real error under the boilerplate, fix it, commit via the `commit` skill, push, and run
  step 5 after the requested work ends. If an earlier run removed the worktree,
  recreate it with the commands in `worktree`'s **Remove after push**. Retry a job once
  (`glab ci retry <job>` / `gh run rerun <run-id> --failed`) when the project's docs name that suite
  as flaky or the log shows an infrastructure failure; a second failure is real.

## 5. Clean up

When `IN_WORKTREE` is true, run the `worktree` skill's **Remove after push** for `BRANCH`:
it proves the remote tip equals the local tip, then removes the worktree and deletes the
local branch with `branch -d`, and stops on any difference. Move your shell to the main
checkout first (the first `worktree` entry of `git worktree list --porcelain`; `MAIN_WT`
can be unset here because `TARGET` is a remote branch). Worktrees with initialized
submodules need its **Submodules** checks before the one
`--force`. When `IN_WORKTREE` is false, `BRANCH` sits in the main checkout: leave it and say
so. Skip a `locked` worktree and report it.

## 6. Report

State plainly: the commits shipped (`<short> <subject>` each), whether the MR/PR was created
or updated, the same for each submodule MR/PR with the merge order (submodule first, and the
squash warning from `shared/submodules.md` when it applies), the pipeline state at push time
(do not wait unless requested), the merge result or blocker when requested, and the cleanup
result: the removed worktree path and the deleted branch with its last commit ID, or the
reason both stayed. End with a **Links** section in the global link format (AGENTS.md,
**Writing**), with no OSC 8 escapes: the MR/PR URL, submodule MR/PR URLs, pipeline URL, and
ticket URL (when set).

## Hard rules

- Never merge, approve, close, or mark ready unless the user asks.
- Never create or transition tickets from this skill unless asked — reuse keys you find.
- Everything in **Shared rules** of `shared/git-flow.md`.
