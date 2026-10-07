## 5. Optional: --loop [N]

`--loop` implies `--fix`. N is the maximum number of rounds. The default is 3.

1. In each round, rebuild in the review worktree after the earlier round's fixes. Then
   start a new reviewer per [delegation.md](delegation.md) with the current target only.
2. Re-verify, report, and fix as in steps 2–4. Hold behavior-change `question` items for the user.
3. Kill a finding that an earlier round killed, unless its code changed since that round.
4. Stop after a round with no new `bug` or `question` finding, or after N rounds.
5. Report one numbered list of the held `question` items and any `bug` left after round N.

For an MR/PR, push after each round as step 4 says. Keep the review worktree until the
last round. If no sub-agent is available, stop after round 1 and say that the next reviewer
is not independent. Run the full manual pass in round 1. In later rounds, rerun
only manual cases whose behavior that round's fixes changed. With `--deep`, start
both reviewers every round.
