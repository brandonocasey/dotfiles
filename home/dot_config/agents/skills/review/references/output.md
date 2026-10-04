# Review output and cleanup

Brief beats complete-sounding: no padding, no restating the diff.

1. **TLDR line** — one sentence: how many findings survived, and whether any are real bugs
   vs. minor notes.
2. **What the change does** — 1–2 plain-language sentences a non-expert could follow. No
   project codenames without a gloss.
3. **One block per surviving finding**, most-severe first, each led by a severity label:
   `bug` (wrong behavior reachable in production), `question` (design choice worth confirming
   with the author), `requirement` (an explicit repository rule violation), or
   `nit` (optional style feedback, only when requested). Per block:
   - **Where**: file + line. For an MR/PR, add a clickable link (formats in `remote-comments.md`, linked at the end of this step) so the
     comment can be left right there; for local targets, use `path:line` (clickable in the
     terminal).
   - **Why it matters**: 1–3 plain-language sentences — what goes wrong, when, and why it
     matters. Jargon spelled out.
   - **Comment to post** (MR/PR) — ready-to-paste text (this one can be technical): factual,
     no hedging, no AI-flavored preamble; state the failure scenario concretely. Where a
     small code change fixes it, include a suggestion block (syntax in the same file).
     **Fix** (local targets) — the concrete change as a small code snippet or exact edit.
4. **What was checked and cleared** — up to 4 one-line bullets naming candidate issues that
   did not survive verification and why each was killed. This is the proof the review was real.

If nothing survives verification, say so plainly — the cleared list plus "nothing real found"
is a valid result. Do not post anything to the MR/PR unless the user asks; step 6 lists what
`--threads` may post. Print for the user to post. For an MR/PR, put all comments in one copy
file, `review-<number>.md`, numbered by finding, and add follow-ups to it. Report CI and
conflict status separately, with the observed source SHA and job or pipeline links.
Pending checks are unverified, not passing.

Stop this review's servers, browser pages, and background processes when it ends.
Keep a worktree for an open MR/PR so follow-up repairs can reuse it. For a local
review or a merged/closed MR/PR, remove only a worktree this review created,
following the `worktree` skill's **Remove** section. Never remove a pre-existing
worktree. Keep a worktree while repairs or re-verification remain pending.
Run resource cleanup separately from outward steps so a blocked approval or
merge cannot prevent it. Report retained paths and reasons, or the removed path
and any blocker. Explicit cleanup requests still require preservation checks.

For MR/PR comment links and suggestion syntax, read
[remote-comments.md](../references/remote-comments.md). Local reviews do not need it.
