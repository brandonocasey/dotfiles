# Public writing rules

These rules cover text others read later, outside the chat. That means docs,
code comments, commit messages, and MR/PR titles and descriptions. It also
means review comments, MR/PR comments, and ticket text.

The chat writing rules still apply here, except the parts aimed at me. Those
are the result line, `Next:`, `Separately:`, `Run /copy`, status marks,
`agents/output/` files, and reply layout. These rules win where they differ.
Repository templates and conventions win over both.

Each kind of text also has its own rules, which win where they differ:

- Code comments: [comments.md](../code-standards/references/comments.md).
- Docs: [write-docs](../write-docs/SKILL.md).
- Commit messages: [commit](../commit/SKILL.md) **Format**.
- MR/PR titles and descriptions: [ship](../ship/SKILL.md) step 3.
- Review comments: [output.md](../review/references/output.md).
- Tickets: [ticket](../ticket/SKILL.md) **Ticket writing**.

## Checked rules

The `writing-reviewer` reports each break of these rules.

- Write for a teammate who has not seen the chat, the ticket, or the diff.
- Never refer to the session, as in "as discussed", "the user asked", or "per review".
- Never write "this PR" or "this commit".
- Spell out each codename and abbreviation at first use, or drop it.
- Keep sentences to 15 words or fewer, with one idea each.
- Leave out the story of the work. That means attempts, steps, and command logs.
  It also means test runs, file-by-file walkthroughs, and lists of every change.
- Leave out filler such as "this change improves…", hedging, closing recaps, and emojis.
- Delete each sentence that repeats the title, another sentence, the code, or the diff.
- Keep exact facts: numbers, versions, error messages, limits, and scope, such as `1 of 12 runs`.
- Never widen a claim that holds only in some cases.
- Every claim must match the code.
- Docs and comments describe the code as it is, never earlier behavior.
  Changelogs and migration guides are exempt.
- Use bullets only for parallel items, such as several behavior changes.
- Use no Summary, Changes, or Testing headings in commits, MR/PRs, or comments.
- Wrap commit bodies at 72 columns, after a blank line.
- Do not hard-wrap MR/PR descriptions or comments; the web page wraps them.

## Guidance

The reviewer reports these only with a rewrite that is clearly shorter or plainer.

- Lead with why: the problem or need, then the resulting behavior.
- Describe what changed only where the diff does not show it plainly.
- Use plain, everyday words. Prefer concrete words and a short example to abstract terms.
- Explain it as you would to someone new to the project.
- To explain how something works, list real events in order, then their effect.
- Avoid metaphors and idioms.
- Use the fewest words that keep every point. Short means fewer words, not fewer facts.
- Never shorten a useful description just for length.

Verify each claim before posting. Reread, then delete what a reader would not miss.
