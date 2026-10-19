# Review setup

You prepare one review pass for the main session, so it needs no review references
before the spawn. Edit no tracked files. First read the repository's AGENTS.md or
CLAUDE.md; their rules override this file, such as a ban on worktrees (then use the
current checkout). When a step needs judgement this file does not
settle, stop and report the blocker instead of guessing. When the prompt says
`Judgement: allowed`, decide it yourself instead and list each choice in the report.

Input: the target as the user gave it, the task scratch directory, any
review worktree from an earlier pass, and `Skip check: on` or `off`. With several targets, set up one at a time:
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
  If the branch is checked out nowhere, use the `worktree` skill's `references/create.md`.
- Before creating a review worktree, inspect `git worktree list --porcelain` and
  the intended path. Prefer a compatible existing checkout, including a named review
  worktree from another session; discovery never depends on an earlier-pass path.
  Preserve local changes and active work. Reuse is a preference, not a requirement;
  create another worktree when needed. Avoid extra names when safe reuse is possible.
- In a worktree you created, with `.gitmodules`, run
  `git -C <worktree> submodule update --init --recursive`.
- Prepare a new worktree per the `worktree` skill's `references/prepare.md`.
- From the review worktree, per [store.md](store.md): for a GitHub or GitLab MR/PR,
  run `agt review sync --pr <n|url>` (prefixed with `GITLAB_HOST=<host>` for a
  self-hosted GitLab) and keep the target key it prints. Then run
  `agt review status --head <head-sha>` with the store target: `--target <key>` for
  that MR/PR, `--range <pinned range>` for an MR/PR on another forge, a commit or
  range the user named, or a detached local-branch checkout; otherwise no flag,
  also for a branch with a given base
  (`--default-branch <base branch>` when it is not the default branch; store.md
  **Commands**). Run it bare, never filtered. For an own GitHub or
  GitLab MR/PR only, when the prompt says `Skip check: on`,
  `reviews_at_head` is 2 or more, and 0 threads are open, report `skip` with the
  count, run IDs, and any worktree you created, and stop before checks. Never skip
  another target on `reviews_at_head`.

## 3. Checks

- Take the test, lint, and typecheck commands from the repository's CI config or its
  documented scripts (package scripts, Makefile, justfile, CONTRIBUTING). If none are
  documented, fill `Checks` with `none documented; choose and run relevant checks yourself`
  and continue. Report `checks: unclear` only when documented commands conflict.
  Copy commands as written; this is a lookup, not a choice. With `Judgement: allowed`,
  choose among conflicting commands and list the choice.
- In a worktree you created, install dependencies per `prepare.md` whenever the
  repository has a lockfile or dependency manifest, so reviewers and the manual pass
  never install there. In an existing checkout, install only when dependencies are
  missing. Build only when the commands need it.
- Name each log `<check>-<pin-id>.log`, where `<pin-id>` is the head SHA, plus a short
  hash of the diff file for any pin saved as a diff file. Skip a command whose log for this pin
  exists or that the prompt reports as started.
- Start each command once, detached (`nohup`), on the pinned target. Write its full log
  to the scratch directory, ending with an `exit N` line. Do not wait for them.

## 4. MR/PR facts

- Platform. On Forgejo, report `mutations unsupported`.
- CI per **Inspect the target** and **Compare with the target branch** in
  [ci-and-conflicts.md](ci-and-conflicts.md), without reading logs or diagnosing: each
  failed job with its label and both job URLs, the source SHA, pending jobs as pending,
  and mergeability.
- Linked issue, for a GitHub or GitLab MR/PR: run `agt issue --offline find --pr <url>`. Use the
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

A REVIEW.md at the root or in a changed directory may list `High risk:`, `Low risk:`,
and `Skip:` path globs, and what counts as broken in that code.

## 6. Reviewer prompt

Fill this template. Fill the fields and add nothing else: no summary of the change,
focus areas, or earlier findings. `<target>` is the user's target verbatim, followed by
`(pinned <range or diff path>)`; an MR/PR target is its URL. Drop the `Linked issue`
line when there is none.

```text
Review <target> for verified defects. Read-only: no edits, commits,
cleanup, or sub-agents. Never read MR/PR comments, discussions, or threads.
Never run `agt review`.
Worktree: <path>
Steps: follow <absolute path of reviewer-steps.md>, steps 0-2.
Linked issue: <key, title, URL, and a few body lines>
Repository rules: <paths of AGENTS.md / CLAUDE.md / CONTRIBUTING.md / REVIEW.md at the root and in every changed directory>
Checks: <commands with their log paths, or `none`>
Severity scale: `bug` (wrong behavior reachable in production), `question` (design
choice worth confirming with the author), `requirement` (an explicit repository
rule violation), or `nit` (optional style feedback, only when requested). Give each
`bug` a severity: `high` (data loss, security hole, crash, or a broken main path),
`medium` (wrong result on a common path), or `low` (rare edge case or minor effect).
Return raw data: file, line, severity, `pre-existing` when marked, failure scenario,
evidence, tests run. End with `Risk: low|medium|high - <one-line reason>`.
```

Keep the severity scale in sync with [output.md](output.md). The main session converts
the returned prose to `pass end --findings` JSON per [store.md](store.md).

## Report

At most 15 lines: the pin, worktree path, whether you created or reused it, starting
SHA, whether you installed dependencies, each command with its log path, the store
target (`--target <key>` for an MR/PR, `--range <range>`, `--default-branch <ref>`, or
none), the MR/PR facts (with the linked issue), and `risk: <tier> (<rule or paths>)`. Then the filled
prompt in one fenced block. Or report `empty`, `checks: unclear`, or the blocker, with
any worktree you created and any checks you started.
