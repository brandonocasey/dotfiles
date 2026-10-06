---
name: ship
description: Commit, push, and open or update GitHub PRs or GitLab MRs when requested or authorized by Git rules. Supports requested merging.
---

Ship the current branch: push it, open or update the MR/PR, and report. When
the argument names a local branch, run every step from that branch's worktree.
Create one with the `worktree` skill if none exists. For several branches or `all`, read [multiple-branches.md](references/multiple-branches.md)
before selecting or pushing anything. Other argument text is a task to finish first.
Parse `--merge` as an option, not a branch or task name.
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
  subjects. Unset if none. When the repo requires one, settle it per step 3 before the
  commit gate.
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

If `BRANCH` equals `REMOTE_DEFAULT` or `TARGET`, read
[default-branch-recovery.md](references/default-branch-recovery.md) before proceeding.

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
- Record `HEAD_SHA` from `git ls-remote origin refs/heads/<BRANCH>`. Record it
  again after each later push. Step 6 and `merge.md` use it.

## 3. Open or update the MR/PR

- Refresh `EXISTING` before creation. Update it instead of creating a duplicate.
  If its base changed during this run, reread it before deciding the target.
- **Title**: the repo's commit/MR convention — read the repo's AGENTS.md / CLAUDE.md /
  CONTRIBUTING for it. For conventional titles, choose the type with the `commit` skill's
  **Choosing the type** procedure; a squash merge makes the title the commit. Include `TICKET` when set. If the repo requires a ticket and there is
  none, never invent a key:
  - The user asked for a ticket: run [mr-ticket](../mr-ticket/SKILL.md) and use its key.
  - The user said no ticket: ship without one.
  - Otherwise ask once, with the options: create a ticket, no ticket, or use a key.
- **Description**: read [writing.md](references/writing.md) and follow the repository template
  or its default description format.
- Use the recorded `TARGET`. Leave draft state alone unless asked.
- When `TICKET` is set, move it to the open-MR/PR status per [mr-ticket](../mr-ticket/SKILL.md) step 6.

## 4. Finish the requested scope

- With `--merge`, read [merge.md](references/merge.md) and finish that workflow
  before cleanup. It supports GitHub and GitLab through `auto-merge-watch`.
- Honor an explicit monitoring or repair request in the current turn. Keep the
  worktree until that work ends. Without one, report the pipeline URL without waiting.
- Handle CI when the user requests it, or once for jobs that already
  failed when the `review` skill's own-work rule requires it.
  Before repairs or retries, read [ci-repair.md](references/ci-repair.md).

## 5. Clean up

Follow [task-resources.md](../host-preflight/references/task-resources.md): stop
task-owned servers, browser pages, and background processes; remove known
disposable task files, including `.agent/<task>/`. Keep a worktree and its branch while the MR/PR is open, unless the
user requests cleanup. After merge or closure, use the `worktree` skill's
**Remove** section and its preservation checks. If `IN_WORKTREE` is false, leave
the main checkout and its branch in place. Report retained paths and reasons.
Keep any server whose URL is still a requested deliverable, per the global rules.

## 6. Report

State plainly: the commits shipped (`<short> <subject>` each), whether the MR/PR was created
or updated, the same for each submodule MR/PR with the merge order (submodule first, and the
squash warning from `shared/submodules.md` when it applies), the pipeline state at push time
(do not wait unless requested), the merge result or blocker when requested, the `Checked:`
line from the commit gate, and the cleanup
result: the removed worktree path and the deleted branch with its last commit ID, or the
reason both stayed. With several branches, give one line per branch. End with one **Links**
section in the global link format (AGENTS.md, **Writing**), with no OSC 8 escapes: the MR/PR
URL, submodule MR/PR URLs, pipeline URL, preview URL (when set), and ticket URL (when set).

When checking for a deployed preview URL, read
[preview-url.md](references/preview-url.md). Only report platform-confirmed URLs;
never infer one from CI files or wait for deployment.

## Hard rules

- Never merge, approve, close, or mark ready unless the user asks.
- Create or transition tickets only through `mr-ticket`, per step 3. Reuse keys you find.
  Transitions move `TICKET` forward only.
- Everything in **Shared rules** of `shared/git-flow.md`.
