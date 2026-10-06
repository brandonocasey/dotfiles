## 4. Optional: --fix

Run this step when [fix-authorization.md](fix-authorization.md) skips the gate, the user asks (`--fix`, a
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

- **MR/PR**: follow [remote-fixes.md](remote-fixes.md) for refresh,
  repair, verification, commit, push, metadata, and any requested merge.
- **Local branch or commit**: apply the fixes in the branch's worktree, run the repo's
  tests/lint, record the `Checked:` line, and commit per the `commit` skill. For a commit
  or the default branch, first create a fix branch per the `worktree` skill; never commit
  in the main checkout. Do not push. Then remove the worktree if this review created it —
  the commits stay on the branch.
- **Working diff**: apply the fixes in place, record the `Checked:` line, and leave them
  uncommitted unless the user asks to commit.

Report the commits, the `Checked:` line, and the MR/PR link. Remove the worktree per step 3.
End the report with one line: `Ship: pushed <sha> to <branch>` or `Ship: not run (<reason>)`.
