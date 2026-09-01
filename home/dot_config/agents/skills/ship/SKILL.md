---
disable-model-invocation: true
name: ship
description: >
  Ship the current branch for review: commit remaining work in logical chunks, push, open (or
  update) the GitLab MR / GitHub PR, then babysit CI — diagnose failing jobs, separate flaky
  from real, fix and re-push until the pipeline is green. The remote counterpart to the
  local-only land skill. Use when the user says "ship this", "push up an MR/PR", "open a merge
  request / pull request", "create an MR for this", "push and make sure CI passes", or invokes
  /ship.
---

Ship the current branch: push it, open or update the MR/PR, and stay on the pipeline until it
is green. Never merge, approve, close, or mark ready unless the user asks.

## 0. Detect context (always run first)

Read `git-flow.md` from the `shared/` directory next to this skill's own directory — resolve it
against this file's path (`<skills-dir>/shared/git-flow.md`), not against the current working
directory, which is the user's repo. Establish its **Facts**: `BRANCH` and `TARGET`. Additionally:

- `HOST` — from `git remote get-url origin`: `gitlab.com` → `glab`; `github.com` → `gh`;
  self-hosted GitLab → `glab` prefixed with `GITLAB_HOST=<host>`; anything else (forgejo/gitea)
  → a matching CLI if installed, else the host's REST API with a token, else plain `git push`
  and use the create-MR/PR URL the remote prints on push.
- `TICKET` — issue/ticket key (e.g. `PUBS-1234`) from the branch name or unpushed commit
  subjects. Unset if none.

**If `BRANCH` == `TARGET`** (you are on the default branch):

- Only a dirty tree, no unpushed commits: move the work onto a properly named branch (repo
  naming convention — e.g. `<type>/<jira>/<description>` in jwpconnatix repos) using the
  `worktree` skill's **Recover changes made in the main checkout** steps (stash `-u`, add the
  worktree, pop there). Never `git switch` in the main checkout — the `worktree` skill owns that
  rule. Continue from inside the new worktree.
- Local `TARGET` is ahead of `origin/<TARGET>`: STOP and ask which commits should ship on the
  branch — never guess, and never reset or force `TARGET` yourself. Refresh the remote-tracking
  ref first (`git fetch origin <TARGET>`), or a stale ref decides this for you.

## 1. Commit gate

Run the **Commit gate** from `shared/git-flow.md`: chunk via the `commit` skill until
`git status --short` prints nothing, then show `git log --oneline <TARGET>..HEAD`.

## 2. Push

- First push, or new commits on an already-pushed branch: `git push -u origin <BRANCH>`.
- Branch exists on the remote but histories diverged (rebase/amend since last push):
  `git push --force-with-lease origin <BRANCH>`. Never plain `--force`; never any force on
  `TARGET`; never push `TARGET` at all from this skill.
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
- Target the remote default branch unless told otherwise. Leave draft state alone unless asked.

## 4. Babysit CI until green

- Watch the pipeline without blocking: delegate the watching to a background agent per the
  `sub-agents` skill's monitoring section (poll `glab ci status` / `gh run watch`, or list+get
  loops), and keep the user posted on state changes.
- On a failed job, pull its log (`glab ci trace <job>` / `gh run view --log-failed`), find the
  real error under the boilerplate, and classify:
  - **Flaky** — the project's docs/skills name known-flaky suites (e.g. web-player `test-pw`
    shards / ad-suite Playwright specs), or it is an infra hiccup (runner died, registry
    timeout): retry the job once (`glab ci retry <job>` / `gh run rerun --failed`). Fails
    again → treat as real.
  - **Real** — fix it in this checkout, commit via the `commit` skill, push, and re-watch.
    Failing CI on a branch you shipped is yours to fix; do not hand it back to the user.
- Repeat until the pipeline is green. STOP and ask only when the fix would change the scope of
  the MR or needs a decision only the user can make — include the failing log excerpt.

## 5. Report

State plainly: the commits shipped (`<short> <subject>` each), whether the MR/PR was created
or updated, and the final pipeline state. End with a **Links** section — MR/PR URL, pipeline
URL, ticket URL (when set) — as bare URLs: no markdown, no brackets, no OSC 8 escapes.

## Hard rules

- Never merge, approve, close, or mark ready unless the user asks.
- `--force-with-lease` only, only on `BRANCH`, never on `TARGET`.
- Never create or transition tickets from this skill unless asked — reuse keys you find.
- Always confirm the push happened before talking about the MR/PR.
- Everything in **Shared rules** of `shared/git-flow.md`.
