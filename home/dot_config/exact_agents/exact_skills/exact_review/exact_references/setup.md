# Review setup

You prepare one review pass for the main session, so it needs no review references
before the spawn. Edit no tracked files. First read the repository's AGENTS.md or
CLAUDE.md; their rules override this file, such as a ban on worktrees (then use the
current checkout). When a step needs judgement this file does not
settle, stop and report the blocker instead of guessing. When the prompt says
`Judgement: allowed`, decide it yourself instead and list each choice in the report.

Input: the target as the user gave it, the task scratch directory, and any
review worktree from an earlier pass. With several targets, set up one at a time:
parallel fetches share `FETCH_HEAD`.

## 1. Pin the target

- **MR/PR URL**: get metadata per [remote-target.md](remote-target.md). Pin
  `<merge-base-sha>..<head-sha>` against the MR/PR's own target branch, never an assumed
  default branch: GitLab `diff_refs.base_sha`; GitHub `git merge-base` of `baseRefOid`
  and `headRefOid` after fetching both.
- **Branch**: pin `<merge-base-sha>..<branch-sha>`, where the merge base is
  `git merge-base <newest-default-base> <branch>`; see **Newest default base** in
  [default-branch.md](../../shared/default-branch.md). A user-given base replaces it.
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
- MR/PR: **Source checkout** in [remote-target.md](remote-target.md). Branch: the
  `worktree` skill's `references/create.md`. Reuse a review worktree from an earlier pass.
- In a worktree you created, with `.gitmodules`, run
  `git -C <worktree> submodule update --init --recursive`.
- Prepare a new worktree per the `worktree` skill's `references/prepare.md`.

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
- Companion or linked MRs/PRs named in the request or description, as URLs.

## 5. Reviewer prompt

Fill this template. Fill the fields and add nothing else: no summary of the change,
focus areas, or earlier findings. `<target>` is the user's target verbatim, followed by
`(pinned <range or diff path>)`; an MR/PR target is its URL.

```text
Review <target> for verified defects. Read-only: no edits, commits,
cleanup, or sub-agents.
Worktree: <path>
Steps: follow <absolute path of reviewer-steps.md>, steps 0-2.
Repository rules: <paths of AGENTS.md / CLAUDE.md / CONTRIBUTING.md that apply>
Checks: <commands with their log paths, or `none`>
Severity scale: `bug` (wrong behavior reachable in production), `question` (design
choice worth confirming with the author), `requirement` (an explicit repository
rule violation), or `nit` (optional style feedback, only when requested). Give each
`bug` a severity: `high` (data loss, security hole, crash, or a broken main path),
`medium` (wrong result on a common path), or `low` (rare edge case or minor effect).
Return raw data: file, line, severity, failure scenario, evidence, tests run.
```

Keep the severity scale in sync with [output.md](output.md).

## Report

At most 15 lines: the pin, worktree path, whether you created or reused it, starting
SHA, whether you installed dependencies, each command with its log path, and the MR/PR facts. Then the filled
prompt in one fenced block. Or report `empty`, `checks: unclear`, or the blocker, with
any worktree you created and any checks you started.
