## Fix authorization

Own work skips the `--fix` gate, whether auto-triggered or user-requested:

- this session's own work;
- the working diff;
- a local branch or commit whose commits all have the author email from
  `git config user.email`;
- an MR/PR whose author is the authenticated user (`gh api user --jq .login` or
  `GITLAB_HOST=<host> glab api user`'s `username`, compared with the MR/PR author).

For own work, apply verified fixes at once per step 4. Re-run tests/lint; follow
[when-to-run.md](when-to-run.md) for follow-up reviews, or step 5 when
`--loop` is set. An own MR/PR gets the full MR/PR flow of step 4, including the push
([git-policy.md](../../shared/git-policy.md)).
For any other target, print the comments and wait for `--fix`. End with:
`Reply fix to apply N findings.`
After a report, a reply that starts with `fix` (`fix`, `fix all`, `fix 2`) means
`--fix` for the same target. Treat every other reply as a normal request.

Before the final review of this session's own work, inspect CI failures that already
finished for any existing task-branch push, once, per
[ci-and-conflicts.md](ci-and-conflicts.md), and fix them. Do not wait for
running CI or push solely to obtain CI before review. Complete the required review
before the next authorized push; without push authorization, review locally.
