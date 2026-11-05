# Public writing rules

These rules cover text others read later, outside the chat: commit messages,
MR/PR titles and descriptions, review and MR/PR comments, ticket text, and code
comments. The main writing rules still apply, except the parts aimed at me in
chat: leading with the result, `Next:`, `Separately:`, `Run /copy`, status
marks, `agents/output/` files, and reply layout. These rules win where they
differ. Repository templates and conventions win over both. Code comments also follow
[comments.md](../code-standards/references/comments.md), which wins where they differ.

- Write for a teammate who has not read the conversation, the ticket, or the diff.
  Never refer to the session: no "as discussed", "the user asked", "per review",
  "this PR", or "this commit".
- Lead with why: the problem or need, then the resulting behavior. Describe what
  changed only where the diff does not show it plainly.
- Use plain, everyday words and sentences of ≤15 words. Spell out codenames and
  abbreviations once, or drop them.
- Keep exact facts: numbers, versions, error messages, limits, and scope, such
  as `1 of 12 runs`. Never generalize a claim limited to some cases. Verify each
  claim before posting.
- Leave out file-by-file walkthroughs, lists of every change, command logs,
  process ("first I tried…"), filler ("this change improves…"), hedging, and emojis.
- Use bullets only for parallel items, such as several behavior changes. No
  Summary/Changes/Testing headings.
- Wrap commit bodies at 72 columns, with a blank line after the title. Do not
  hard-wrap MR/PR descriptions or comments; the web view wraps them.
- Reread before posting. Delete each sentence that repeats the title, another
  sentence, or the diff.
