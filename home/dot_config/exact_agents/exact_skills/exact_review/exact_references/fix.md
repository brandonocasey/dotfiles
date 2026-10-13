## Fix authorization

Own work skips the `--fix` gate, whether auto-triggered or user-requested:

- this session's own work;
- the working diff;
- a local branch or commit whose commits all have the author email from
  `git config user.email`;
- an MR/PR whose author is the authenticated user (`gh api user --jq .login` or
  `GITLAB_HOST=<host> glab api user`'s `username`, compared with the MR/PR author).

For own work, apply verified fixes at once per step 4. Re-run tests/lint; step 5's
fix loop owns follow-up reviews. An own MR/PR gets the full MR/PR flow of step 4, including the push
([git-policy.md](../../shared/git-policy.md)).
For any other target, print the comments and wait for `--fix`. End with:
`Reply fix to apply N findings.`
After a report, a reply that starts with `fix` (`fix`, `fix all`, `fix 2`) means
`--fix` for the same target. Treat every other reply as a normal request.

Before the final review of this session's own work, inspect already-finished CI
failures of any existing task-branch push, once, per
[ci-and-conflicts.md](ci-and-conflicts.md), and fix them. Never wait for CI or
push solely to obtain it. During `ship`, skip this when the push starts a new
pipeline. Without push authorization, review locally.

## 4. Optional: --fix

Run this step when **Fix authorization** skips the gate, the user asks (`--fix`, a
`fix` reply, or a later fix request for the same MR/PR), or `--threads` has `valid`
threads that the request covers (fix only those threads):

- **Scope**: fix every surviving `bug` and `requirement`, unless the user names
  a subset. Fix `nit` items only when style changes are requested.
- **Behavior changes**: do not apply a fix that changes user-visible behavior beyond
  what the change or its spec intends. Report it as a `question` with options and a
  recommended default.
- **Questions**: if the answer does not change user-visible behavior, choose the
  recommended answer, apply it, and state the choice in one line.
- With `--fix`, never end with comments for the user to post; apply them.
- End with at most one question, for the excluded items only.

Fix authorization also covers CI failures and clear conflicts for the review target.
Read [ci-and-conflicts.md](ci-and-conflicts.md) before these repairs.

- **MR/PR**: in the review worktree:
  1. Refresh the source branch per **Resolve conflicts** in
     [ci-and-conflicts.md](ci-and-conflicts.md); drop stale findings.
  2. Apply the verified fixes. Do not expand the repair into optional comment
     or style cleanup unless requested.
  3. Resolve clear conflicts with the target branch and fix `new in this change` CI
     failures, per [ci-and-conflicts.md](ci-and-conflicts.md).
  4. Run the repo's tests/lint. Check the fixed HEAD per `shared/git-flow.md`
     **Manual check** (methods in [manual-testing.md](manual-testing.md)
     **Exercise the actual behavior**). Record `Checked: <steps, page or command, config> -> <result>`;
     text-only fixes record `Checked: diff only`.
  5. Commit through the `commit` skill. Keep the branch's scope and ticket style, but take
     the type from its **Choosing the type** procedure; carry any issue-tracker reference
     from the MR/PR title. Handle auto-merge per `shared/auto-merge-pause.md`
     (pause at start, restore after the push, new MR/PR when queued). Push to the source branch — the review
     worktree is detached, so use `git push origin HEAD:<source-branch>`. For a fork MR/PR,
     `origin` is the base repo: push to the fork's URL instead
     (`git push <fork-url> HEAD:<source-branch>`). That needs push access to the fork and
     leaves the git config unchanged.
  6. Sync the title and description to the final diff, per `ship` step 3, and read them
     back. Then refresh the source SHA, CI, and mergeability once, per [ci-and-conflicts.md](ci-and-conflicts.md).
  7. Clean up per step 3. Then run step 7 ([approve-merge.md](approve-merge.md)) when
     `--approve`, `--auto-merge`, or `--merge` is set.
- **Local branch or commit**: apply the fixes in the branch's worktree, run the repo's
  tests/lint, record the `Checked:` line, and commit per the `commit` skill. For a commit
  or the default branch, first create a fix branch per the `worktree` skill. Do not push.
- **Working diff**: apply the fixes in place, record the `Checked:` line, and leave them
  uncommitted unless the user asks to commit.

Report the commits, the `Checked:` line, and the MR/PR link. Clean up per step 3.
End with the `Ship:` line defined in [work-output.md](../../shared/work-output.md).
