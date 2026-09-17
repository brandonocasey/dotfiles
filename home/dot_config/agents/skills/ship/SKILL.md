---
disable-model-invocation: true
name: ship
description: >
  Commit, push, and open or update a GitHub PR or GitLab MR. Use for shipping
  or PR/MR creation requests; do not wait for CI.
---

Ship the current branch: push it, open or update the MR/PR, and report. Do not watch the
pipeline. Never merge, approve, close, or mark ready unless the user asks.

## 0. Detect context (always run first)

Read `git-flow.md` from the `shared/` directory next to this skill's own directory — resolve it
against this file's path (`<skills-dir>/shared/git-flow.md`), not against the current working
directory, which is the user's repo. Establish its **Facts** using these remote
target details:

- `HOST` — from `git remote get-url origin`: `gitlab.com` → `glab`; `github.com` → `gh`;
  self-hosted GitLab → `glab` prefixed with `GITLAB_HOST=<host>`; anything else (forgejo/gitea)
  → a matching CLI if installed, else the host's REST API with a token, else plain `git push`
  and use the create-MR/PR URL the remote prints on push.
- `TICKET` — issue/ticket key (e.g. `PUBS-1234`) from the branch name or unpushed commit
  subjects. Unset if none.
- `REMOTE_DEFAULT` — resolve `origin` through **Remote default name** in
  [default-branch.md](../shared/default-branch.md). Never use a cached
  `origin/HEAD` to decide whether a branch is safe to push.
- `TARGET` — the user's explicit MR/PR target, or `REMOTE_DEFAULT`. Fetch it with
  `git fetch origin refs/heads/<TARGET>` and immediately record
  `git rev-parse FETCH_HEAD` as `COMMIT_BASE`. Do not require a local target branch
  or assume that the fetch updated `origin/<TARGET>` under a restricted refspec.

**If `BRANCH` equals `REMOTE_DEFAULT` or `TARGET`**:

- Fetch `refs/heads/<BRANCH>` from `origin` and record its commit ID before
  comparing it with local `HEAD`. If local commits are ahead or histories
  diverge, ask which commits should ship on a new branch. Never guess, reset,
  or force the checked-out branch. Stop on a missing remote branch or failed fetch.
- With a dirty tree and no local-only commits, move the work onto a properly named branch (repo
  naming convention — e.g. `<type>/<jira>/<description>` in jwpconnatix repos) using the
  `worktree` skill's **Recover changes made in the main checkout** steps. Never
  `git switch` in the main checkout — the `worktree` skill owns that
  rule. Continue from inside the new worktree and refresh `BRANCH`.
- With a clean tree and no local-only commits, report that there is nothing to ship and stop.

When `.gitmodules` exists, also read `shared/submodules.md` next to `git-flow.md` and
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
- Confirm the push landed (`git status -sb` shows no ahead-count) and say so — the user should
  never have to ask "did you push?".

## 3. Open or update the MR/PR

- Check for an existing open MR/PR for `BRANCH` first (`glab mr list --source-branch <BRANCH>`
  / `gh pr list --head <BRANCH>`). Update it instead of creating a duplicate.
- **Title**: the repo's commit/MR convention — read the repo's AGENTS.md / CLAUDE.md /
  CONTRIBUTING for it (e.g. jwpconnatix: `<type>(<scope>): <subject> [PUBS-1234]`). Include
  `TICKET` when set. If the repo requires a ticket and there is none, ask the user for the key
  — never invent one, never create tickets from this skill unless asked.
- **Description**: 2 sentences max — what changed and the approach. Add the config/data used
  for testing when the repo convention asks for it. No product framing, no filler, no
  checklists.
- Use the recorded `TARGET`. Leave draft state alone unless asked.

## 4. Do not watch CI

- Do not poll the pipeline, and do not spawn a background agent to watch it. Report the
  pipeline URL and stop.
- Handle CI only when the user asks for it in a later turn. Then: pull the failing job's log
  (`glab ci trace <job>` / `gh run view --log-failed`), find the real error under the
  boilerplate, fix it, commit via the `commit` skill, push, and run step 5 again. Step 5
  removed the worktree, so recreate it first with the two commands at the end of the
  `worktree` skill's **Remove after push**. Retry a job
  once (`glab ci retry <job>` / `gh run rerun --failed`) when the project's docs name that
  suite as flaky or the failure is an infra hiccup; a second failure is real.

## 5. Clean up

When `IN_WORKTREE` is true, run the `worktree` skill's **Remove after push** for `BRANCH`:
it proves the remote tip equals the local tip, then removes the worktree and deletes the
local branch with `branch -d`, and stops on any difference. Move your shell to `MAIN_WT`
first. Worktrees with initialized submodules need its **Submodules** checks before the one
`--force`. When `IN_WORKTREE` is false, `BRANCH` sits in the main checkout: leave it and say
so. Skip a `locked` worktree and report it.

## 6. Report

State plainly: the commits shipped (`<short> <subject>` each), whether the MR/PR was created
or updated, the same for each submodule MR/PR with the merge order (submodule first, and the
squash warning from `shared/submodules.md` when it applies), the pipeline state at push time
(do not wait for it to finish), and the cleanup
result: the removed worktree path and the deleted branch with its last commit ID, or the
reason both stayed. End with a
**Links** section — MR/PR URL, submodule MR/PR URLs, pipeline URL, ticket URL (when set) — as bare URLs: no markdown, no brackets, no OSC 8 escapes.

## Hard rules

- Never merge, approve, close, or mark ready unless the user asks.
- `--force-with-lease` only, only on `BRANCH`, never on `TARGET` or the live remote default.
- Never create or transition tickets from this skill unless asked — reuse keys you find.
- Always confirm the push happened before talking about the MR/PR.
- Remove the worktree and local branch only after the `ls-remote` check in **Remove after
  push** passes. Never `branch -D`.
- Everything in **Shared rules** of `shared/git-flow.md`.
