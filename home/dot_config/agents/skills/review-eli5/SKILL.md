---
name: review-eli5
description: >
  Verified GitLab MR review with an ELI5 summary. Runs the full review-mr flow (fetch via
  glab, review the diff, VERIFY every candidate finding against the real code in a worktree),
  then reports each issue/comment/suggestion in plain language with the exact spot to leave
  the comment. Use when the user asks to "review and ELI5", "explain the issues simply",
  "review and verify then summarize", or invokes /review-eli5 with an MR URL. (For the
  standard technical-comment output, use /review-mr instead.)
---

Run steps 0–2 of the `review-mr` skill exactly (fetch with glab, review the diff, verify
every candidate finding against the actual code in a `.worktrees/review-<iid>` worktree —
kill anything you cannot make concrete). The repo may not be the current working directory:
locate the local checkout for the MR's project path first and create the worktree there.

Then produce THIS output format instead of review-mr's:

## Output format

1. **TLDR line** — one sentence: how many comments survived, and whether any are real bugs
   vs. minor notes.
2. **What the MR does (ELI5)** — 1–2 plain-language sentences a non-expert could follow.
   No project codenames without a gloss.
3. **One block per surviving comment**, most-severe first:
   - **Where to comment**: file + line, plus a clickable link directly to that line in the
     MR's Changes tab so the user can comment right there:
     `https://gitlab.com/<project>/-/merge_requests/<iid>/diffs#<sha1>_<old>_<new>`
     where `<sha1>` = `printf '<repo-relative-file-path>' | shasum -a 1` and `<old>`/`<new>`
     are the diff positions of the line: walk the hunk from its `@@ -o,c +n,c @@` header —
     context lines increment both counters, `-` lines only the old, `+` lines only the new;
     an added line's `<old>` is the current (unincremented) old counter. For file-wide notes
     (e.g. lockfile churn) link `.../diffs#<sha1>` (file header anchor). Fall back to a
     source-branch blob link (`/-/blob/<branch>/<file>#L<line>`) only for lines outside the
     MR diff.
   - **ELI5**: 1–3 sentences explaining the issue as if to someone new to the codebase —
     what goes wrong, when, and why it matters. Analogies welcome, jargon spelled out.
   - **Comment to post**: the ready-to-paste MR comment text (this one can be technical),
     with a GitLab `suggestion` block when a small code change fixes it.
4. **What was checked and cleared** — 2–4 bullets naming the candidate issues that did NOT
   survive verification and the one-line reason each was killed. This is the proof the
   review was real; keep each bullet to one line.

Rules:

- Brief beats complete-sounding: no padding, no restating the diff, no findings you
  couldn't make concrete. "Nothing real found" plus the cleared-list is a valid result.
- Severity labels: `bug` (wrong behavior reachable in production), `question` (design
  choice worth confirming with the author), `nit` (cosmetic/noise). Lead each comment
  block with its label.
- Do NOT post anything to the MR; print for the user to post.
- Clean up the review worktree when done.
