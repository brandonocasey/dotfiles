# Review output and cleanup

Each finding or comment covers one issue in at most three sentences: what
breaks, when, and the fix. Apply repository templates when present.

Long reports follow the long-output rule in
[writing-details.md](../../shared/writing-details.md). Comment blocks the user
posts by hand print per `host-preflight/references/copyable-output.md`.

1. **TLDR line** — one sentence: how many findings survived, whether any are real bugs
   vs. minor notes, how many are pre-existing, and the risk tier with its reason.
2. **What the change does** — 1–2 plain-language sentences a non-expert could follow. No
   project codenames without a gloss.
3. **One block per surviving finding**, most-severe first, each led by a severity label:
   `bug` (wrong behavior reachable in production), `question` (design choice worth confirming
   with the author), `requirement` (an explicit repository rule violation), or
   `nit` (optional style feedback, only when requested).
   Give each `bug` a severity: `high` (data loss, security hole, crash, or a broken main
   path), `medium` (wrong result on a common path), or `low` (rare edge case or minor
   effect). Per block:
   - **Where**: file + line. For an MR/PR, add a clickable link so the
     comment can be left right there; for local targets, use `path:line` (clickable in the
     terminal).
   - **Why it matters**: plain language, jargon spelled out.
   - **Comment to post** (MR/PR) — ready-to-paste, may be technical; state the
     failure scenario concretely. Where a small code change fixes it, include a
     suggestion block.
     **Fix** (local targets) — the concrete change as a small code snippet or exact edit.
   A security finding keeps its `Security (<class>):` lead-in.
4. **Pre-existing** — defects the change did not introduce, after the change's
   findings, in the same block format, each marked `pre-existing`. They are not the
   author's fault and never block approval; [fix.md](fix.md) **Scope** owns fixing them.
5. **What was checked and cleared** — one one-line bullet per candidate issue that
   did not survive verification and why each was killed. This is the proof the review was real.

If nothing survives verification, say so plainly — the cleared list plus "nothing real found"
is a valid result. For a GitHub or GitLab MR/PR, run `agt review sync --pr <n|url>`
(with `GITLAB_HOST=<host>` for a self-hosted GitLab), then
`agt review list --target <key>` once for every thread with its resolved state
([store.md](store.md)). Then:
- A finding that matches a thread with a `review-finding` or `agent-review` marker,
  open or resolved, is kept, reported, and fixed as usual, but not added again. On an
  own MR/PR, `resolve` that thread as fixed once this run fixes it, or reopen it as
  `not fixed` when it is resolved and this run did not fix it.
- A finding that matches any other open thread is already raised: drop it.
- A finding that matches any other resolved thread was settled by a person: drop it
  and name it in the cleared list.
- Every open review-marked thread that no finding matched stays an open item
  (`agt review list --open`): list it in the report and in the loop's step 5 list,
  so the step 7 gate sees it.

On an own GitHub or GitLab MR/PR, post per **Own MR/PR comments** in
[remote-comments.md](remote-comments.md) and link each posted comment instead of
printing comment blocks; the comment text goes only into the store. Otherwise do not
post anything to the MR/PR unless the user asks. Then show the user
`agt review publish --not-own --only <finding ids the user chose> --dry-run`,
and run it without `--dry-run` only when the dry-run writes match the request. Step 6 lists what `--threads` may
post. Print for the user to post, per `host-preflight/references/copyable-output.md`:
one fenced block per comment, numbered by finding. Report CI and
conflict status separately, with the observed source SHA and job or pipeline links.
Pending checks are unverified, not passing.

When the review ends, clean up per `host-preflight/references/task-resources.md`
and remove the worktree this review created, following the `worktree` skill's
**Remove** section, including for open MRs/PRs. Exception: keep an open MR/PR's
worktree when this review installed dependencies in it, so follow-up repairs can
reuse them. Never remove a pre-existing worktree, except under `--merge` step 7
cleanup. Keep a worktree while repairs or re-verification in this run remain
pending. Run cleanup separately from outward steps so a blocked approval or
merge cannot prevent it. Never delete or prune `agt review` store data; the
store ages it out itself. Report retained paths and reasons, or the removed path
and any blocker.

For MR/PR comment links and suggestion syntax, read
[remote-comments.md](remote-comments.md). Local reviews do not need it.
