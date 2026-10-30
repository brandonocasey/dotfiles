# Review setup

The main session prepares one review pass itself with `agt`, `git`, and `gh`/`glab`
commands; no sub-agent. Read file paths, metadata, and CI status only, never the
changed code or diff content. Edit no tracked files. The repository's AGENTS.md or
CLAUDE.md override this file, such as a ban on worktrees (then use the current
checkout). When a step needs judgement this file does not settle, decide it and list
each choice in the report.

Input: the target as the user gave it, the task scratch directory, any
review worktree from an earlier pass, and the skip check, on or off. With several targets, set up one at a time:
parallel fetches share `FETCH_HEAD`.

## 1. Pin the target

- **MR/PR URL**: get metadata per [remote-target.md](remote-target.md). Pin
  `<merge-base-sha>..<head-sha>` against the MR/PR's own target branch, never an assumed
  default branch: GitLab `diff_refs.base_sha`; GitHub `git merge-base` of `baseRefOid`
  and `headRefOid` after fetching both.
- **Branch** (also "branch X against Y"): pin `<merge-base-sha>..<branch-sha>`, where the merge base is
  `git merge-base <newest-default-base> <branch>`; see **Newest default base** in
  [default-branch.md](../../shared/default-branch.md). A user-given base replaces it.
  When an open MR/PR by the authenticated user has the branch SHA as its head, pin
  that MR/PR instead and report it as the target, so fixes push and comments land on
  it. Its checkout is the branch's existing worktree when it has one, so the local
  branch keeps the fixes; otherwise **Source checkout**.
- **Commit or range**: its own SHA or range.
- **Other explicit target** (a range plus the working tree, a range-diff): pin it as
  given; save a combined diff to a file in the scratch directory.
  Name every saved diff `diff-<short-hash>.diff`, so passes never overwrite each other.
- **No argument**: the working diff (`git diff HEAD` plus untracked files), saved to a
  file in the scratch directory, when the tree is dirty; otherwise the current branch,
  pinned as a branch.

If the pinned diff is empty, report `empty` and stop.

## 2. Checkout

- Working diff, commit, range, or other explicit target: the earlier worktree when the
  prompt gives one, else the current checkout.
- MR/PR: **Source checkout** in [remote-target.md](remote-target.md). Branch: prefer
  a suitable existing checkout (`git worktree list`). If it is unsuitable, create
  a detached review worktree at the pinned head without disturbing that checkout.
  If the branch is checked out nowhere, run `agt worktree create <branch> --prepare`.
- Before creating a review worktree, inspect `git worktree list --porcelain` and
  the intended path. Prefer a compatible existing checkout, including a named review
  worktree from another session; discovery never depends on an earlier-pass path.
  Preserve local changes and active work. Reuse is a preference, not a requirement;
  create another worktree when needed. Avoid extra names when safe reuse is possible.
- In a worktree you created, with `.gitmodules`, run
  `git -C <worktree> submodule update --init --recursive`.
- From the review worktree, per [store.md](store.md): for a GitHub or GitLab MR/PR,
  run `agt review sync --pr <n|url>` (prefixed with `GITLAB_HOST=<host>` for a
  self-hosted GitLab) and keep the target key it prints. Then run
  `agt review status --head <head-sha>` with the store target: `--target <key>` for
  that MR/PR, `--range <pinned range>` for an MR/PR on another forge, a commit or
  range the user named, or a detached local-branch checkout; otherwise no flag,
  also for a branch with a given base
  (`--default-branch <base branch>` when it is not the default branch; store.md
  **Commands**). Run it bare, never filtered. For an own GitHub or
  GitLab MR/PR only, when the skip check is on,
  `reviews_at_head` is 2 or more, and 0 threads are open, report `skip` with the
  count, run IDs, and any worktree you created, and stop before checks. Never skip
  another target on `reviews_at_head`.

## 3. Checks

- Take the test, lint, and typecheck commands from the repository's CI config or its
  documented scripts (package scripts, Makefile, justfile, CONTRIBUTING). If none are
  documented, fill the tester prompt's `Checks` with `none documented; choose relevant ones`
  and continue. Copy commands as written. When documented commands conflict, choose
  and list the choice.
- `agt worktree create --prepare` (also with `--detach`) installs dependencies in a new
  worktree. After a plain `git worktree add`, run `agt worktree prepare <worktree>` once. Reviewers and the tester never install there. In an existing checkout, install only when dependencies are
  missing. Build only when the commands need it.
- Run none of the commands. The tester runs them ([testing.md](testing.md)).

## 4. MR/PR facts

- Platform. On Forgejo, report `mutations unsupported`.
- CI per **Inspect the target** and **Compare with the target branch** in
  [ci-and-conflicts.md](ci-and-conflicts.md), without reading logs or diagnosing: each
  failed job with its label and both job URLs, the source SHA, pending jobs as pending,
  and mergeability.
- Linked issue, for a GitHub or GitLab MR/PR: run `agt --offline issue list --pr <url>`. Use the
  MR/PR URL, not a bare number: a number matches that PR in every synced tracker.
  Add `--tracker <owner/repo>` when only a number is known. The command is read-only
  and uses the local copy, so never run `sync` or any write. It returns no body. Report
  each hit's key, title, and URL. For context, `agt issue show <key>` may add the
  first few lines of the body. Report nothing and continue when `agt` or a tracker
  is missing, or the command fails.
- Companion or linked MRs/PRs named in the request or description, as URLs.
- Whether the authenticated user authored the MR/PR (`own: yes` or `own: no`).
- Prior reviews of the pinned head from the step 2 `status`: `reviews_at_head`, the
  open threads, and the run IDs. Report `prior reviews: 0` when none.

## 5. Risk tier

Set the tier from the pinned diff; the highest matching rule wins. When a path's role
is unclear, choose the higher tier.

- `high`: auth, permissions, payments, database migrations, CI or deploy config
  (`.github/workflows`, `.gitlab-ci.yml`, `Jenkinsfile`, Dockerfiles, infra),
  dependency manifests or lockfiles, or secret handling; or a path under a REVIEW.md
  `High risk:` glob.
- `low`: only documentation, Markdown, comments, test files, or REVIEW.md `Low risk:`
  globs changed, in under 400 changed lines.
- `medium`: everything else.

Also report the changed-line count and a review mode, from the pinned diff:

- `haiku`: tier `low`. Reviewer runs at `xhigh`.
- `opus`: everything else.

A REVIEW.md at the root or in a changed directory may list `High risk:`, `Low risk:`,
and `Skip:` path globs, and what counts as broken in that code.

## 6. Reviewer prompt

Fill this template. Fill the fields and add nothing else: no summary of the change,
focus areas, or earlier findings. `<target>` is the user's target verbatim, followed by
`(pinned <range or diff path>)`; an MR/PR target is its URL. Drop the `Linked issue`
line when there is none.

```text
Review <target> for verified defects.
Worktree: <path>
Steps: follow <absolute path of reviewer-steps.md>, steps 0-2.
Linked issue: <key, title, URL, and a few body lines>
Repository rules: <paths of AGENTS.md / CLAUDE.md / CONTRIBUTING.md / REVIEW.md at the root and in every changed directory>
```

The `reviewer` role sets the severity scale, return format, and read-only limits;
[output.md](output.md) uses the scale. The main session converts
the returned prose to `pass end --findings` JSON per [store.md](store.md).

## Record

Keep for later steps and report in at most 15 lines: the pin, worktree path, whether you created or reused it, starting
SHA, whether you installed dependencies, each check command, the store
target (`--target <key>` for an MR/PR, `--range <range>`, `--default-branch <ref>`, or
none), the MR/PR facts (with the linked issue), and `risk: <tier> (<rule or paths>)`, `lines: <N>`, and `mode: haiku|opus`.
Or report `empty` or the blocker, with any worktree you created.
