## Fix authorization

Own work skips the `--fix` gate, whether auto-triggered or user-requested:

- this session's own work;
- the working diff;
- a local branch or commit whose commits all have the author email from
  `git config user.email`;
- an MR/PR whose author is the authenticated user (`gh api user --jq .login` or
  `GITLAB_HOST=<host> glab api user`'s `username`, compared with the MR/PR author).

For own work, apply verified fixes at once per step 4. Retest them per **Retest** in
[testing.md](testing.md); step 5's
fix loop owns follow-up reviews. An own MR/PR gets the full MR/PR flow of step 4, including the push
([git-policy.md](../../shared/git-policy.md)).
For any other target, print the comments and wait for `--fix`. End with:
`Reply fix to apply N findings.`
After a report, a reply that starts with `fix` (`fix`, `fix all`, `fix 2`) means
`--fix` for the same target. Treat every other reply as a normal request.

## 4. Optional: --fix

Run this step when **Fix authorization** skips the gate, the user asks (`--fix`, a
`fix` reply, or a later fix request for the same MR/PR), or `--threads` has `valid`
threads that the request covers (fix only those threads):

- **Scope**: fix every surviving `bug` and `requirement`, unless the user names
  a subset. Fix `nit` items only when style changes are requested. Never fix a
  `pre-existing` finding on the reviewed branch. When the user names one, fix it on
  its own branch and MR/PR from the default branch (`worktree` skill), outside this
  review: that fix starts no fix check, run, or review of this target.
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
  4. Retest the fixed HEAD per **Retest** in [testing.md](testing.md), which covers
     `shared/git-flow.md` **Manual check**. Record `Checked: <steps, page or command, config> -> <result>`;
     text-only fixes record `Checked: diff only`.
  5. Commit through the `commit` skill. Keep the branch's scope and ticket style, but take
     the type from its **Choosing the type** procedure; carry any issue-tracker reference
     from the MR/PR title. Never mention the review, its passes, or its findings in
     the commit message or MR/PR description. Handle auto-merge per `shared/auto-merge-pause.md`
     (pause at start, restore after the push, new MR/PR when queued; inside the fix loop keep it paused per loop.md). Push to the source branch — the review
     worktree is detached, so use `git push origin HEAD:<source-branch>`. For a fork MR/PR,
     `origin` is the base repo: push to the fork's URL instead
     (`git push <fork-url> HEAD:<source-branch>`). That needs push access to the fork and
     leaves the git config unchanged.
  6. Sync the title and description to the final diff, per `ship` step 3, and read them
     back. Then refresh the source SHA, CI, and mergeability once, per [ci-and-conflicts.md](ci-and-conflicts.md).
  7. Continue into step 5's fix loop. [loop.md](loop.md) runs cleanup and step 7
     ([approve-merge.md](approve-merge.md)) once, after the loop ends.
- **Committed fixes** (MR/PR, local branch, or commit): add each fix as a new commit,
  even where the `commit` skill would amend. Until the review ends, never amend,
  squash, or rebase reviewed commits, so threads and coverage stay on them. Only a
  rebase the user authorizes ([ci-and-conflicts.md](ci-and-conflicts.md)) is exempt.
- **Local branch or commit**: do not create a review- or fix-specific branch when the
  reviewed branch can take the fixes. For a local branch, commit the fixes onto it in its
  own worktree, keeping the selected range store target, unless another agent or session
  is working in that worktree (`git worktree list`, `agt worktree remove` plan's process
  check). Only then, or for a commit or the default branch (no task branch exists), create
  a fix branch per the `worktree` skill, preserving the original branch and checkout, and
  report it. A detached review worktree attaches to the branch only when the branch is
  checked out nowhere else. Retest per **Retest** in [testing.md](testing.md), record the
  `Checked:` line, and commit per the `commit` skill. Do not push. Clean up any fix branch
  you created per **Remove after push** in the `worktree` skill's [remove.md](../../worktree/references/remove.md).
- **Working diff**: apply the fixes in place, retest per **Retest** in
  [testing.md](testing.md), record the `Checked:` line, and leave them
  uncommitted unless the user asks to commit.

Report the commits, the `Checked:` line, and the MR/PR link. Clean up per step 3.
End with the `Ship:` line defined in [work-output.md](../../shared/work-output.md).
