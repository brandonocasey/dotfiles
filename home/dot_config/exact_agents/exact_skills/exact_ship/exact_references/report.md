## 6. Report

State plainly: the commits shipped (`<short> <subject>` each), whether the MR/PR was created
or updated, the same for each submodule MR/PR with the merge order (submodule first, and the
squash warning from `shared/submodules.md` when it applies), the pipeline state at push time,
the review result (findings, fixes, fix push) or why it was skipped, auto-merge paused
and restored or still paused, any CI watch result
already in,
whether the CI watch is running or why it was skipped (do not wait for it), the merge result or blocker when requested, the `Checked:`
line from the commit gate, and the cleanup
result: the removed worktree path and the deleted branch with its last commit ID, or the
reason both stayed. With several branches, give one line per branch. End with one **Links**
section in the link format of [writing-details.md](../../shared/writing-details.md), with no OSC 8 escapes: the MR/PR
URL, submodule MR/PR URLs, pipeline URL, preview URL (when set), and ticket URL (when set).

When checking for a deployed preview URL, read
[preview-url.md](preview-url.md). Only report platform-confirmed URLs;
never infer one from CI files or wait for deployment.
