# Repair an MR/PR

Use only after the review skill's **Fix authorization** and step 4 authorize
these repairs. Step numbers below refer to the review skill.

- **MR/PR**: in the review worktree:
  1. Fetch the source branch. If its head moved, check each finding again and drop stale ones.
  2. Apply the verified fixes. Do not expand the repair into optional comment
     or style cleanup unless requested.
  3. Resolve clear conflicts with the target branch and fix `new in this change` CI
     failures, per [ci-and-conflicts.md](ci-and-conflicts.md).
  4. Run the repo's tests/lint. Check the fixed HEAD by hand (AGENTS.md manual-check rule;
     methods in [manual-testing.md](manual-testing.md) **Exercise the actual behavior**). Record one line:
     `Checked: <steps, page or command, config> -> <result>`. Text-only fixes record
     `Checked: diff only`; test-only fixes run the changed tests; classify config by effect.
  5. Commit through the `commit` skill. Keep the branch's scope and ticket style, but take
     the type from its **Choosing the type** procedure; carry any issue-tracker reference
     from the MR/PR title. Push to the source branch — the review
     worktree is detached, so use `git push origin HEAD:<source-branch>`. For a fork MR/PR,
     `origin` is the base repo: push to the fork's URL instead
     (`git push <fork-url> HEAD:<source-branch>`). That needs push access to the fork and
     leaves the git config unchanged.
  6. Sync the title and description to the final diff, per `ship` step 3, and read them
     back. Then refresh the source SHA, CI, and mergeability once, per [ci-and-conflicts.md](ci-and-conflicts.md).
  7. Clean up per step 3. Then run step 7 ([approve-merge.md](approve-merge.md)) when
     `--approve`, `--auto-merge`, or `--merge` is set.
