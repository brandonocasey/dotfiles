## 6. Report

State plainly:

- The commits shipped (`<short> <subject>` each).
- Whether the MR/PR was created or updated, and the same for each submodule
  MR/PR with the merge order (submodule first, plus the squash warning from
  [submodules.md](../../shared/submodules.md) when it applies).
- The pipeline state at push time.
- The review result (findings, fixes, fix push) or why it was skipped.
- Auto-merge paused and restored, or still paused.
- Any CI watch result already in, or whether the watch is running (do not wait
  for it) or why it was skipped.
- The merge result or blocker when requested.
- The `Checked:` line from the commit gate.
- The cleanup result: the removed worktree path and the deleted branch with its
  last commit ID, or the reason both stayed.

With several branches, give one line per branch. End with one **Links**
section in the link format of [writing-details.md](../../shared/writing-details.md),
with no OSC 8 escapes: the MR/PR URL, submodule MR/PR URLs, the pipeline URL only
when it failed, preview URL (when set), and ticket URL (when set).

When checking for a deployed preview URL, read [preview-url.md](preview-url.md).
