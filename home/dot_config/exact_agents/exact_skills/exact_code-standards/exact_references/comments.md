## Code comments

- Comment only what the code cannot show: a reason, constraint, workaround, required behavior, or warning about code that deliberately breaks convention. Do not repeat what the code says or describe the change; put the bug, investigation, and ticket in the commit message. Remove redundant comments, and update or remove comments when the code changes. Each comment must make sense to someone who has not read the conversation.
- Put the comment at the method or block level, in 1–2 complete sentences
- These rules cover doc comments too. A doc comment states what the item does and its contract in one sentence; link a sibling instead of re-explaining it: `Like [compress], but takes ownership of the hunk.`
- Never write, in code or doc comments: why you added the item or how your caller uses it ("so it can be sent to another thread", "such as when…"); a constant's justification with estimates ("~32 MiB, enough to ride out latency spikes"); earlier behavior ("the old", "previously", "now", "no longer"); or what the signature already shows (owns, borrows, `'static`, `Send`)
- In a repository you do not own (upstream PRs, forks), match its comment density: add no more comment lines per function than nearby code has, and follow its doc style. Put rationale in the PR description, not the code
- Before each commit, reread every comment you added and delete each one a reader would not miss. When unsure, delete it
- When a reviewer flags one comment, treat it as a sample: reread every comment the whole PR adds, against these rules, and fix all of them before pushing
- State a real requirement with a capitalized RFC 2119 keyword (MUST, SHOULD, MAY, …) https://www.rfc-editor.org/rfc/rfc2119 : `Callers MUST hold the lock`. Lowercase in ordinary prose
- Link external context at the point of use: the source of copied code, the spec tricky logic implements, the issue a workaround works around, and `TODO` plus an issue reference for known-incomplete code
