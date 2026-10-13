# Copyable output

Read when preparing commands or text the user must copy.

I copy text with `/copy`. Claude Code and Codex both have it. Make it one step:

- Never write copy files. Put all copyable text in chat, however long.
- Ignore terminal width. Never wrap or shorten copyable text to fit.
- Put each copyable item in its own fenced block, holding only that item: no shell prompts like `$` and no comments. Keep a leading `!` meant for my prompt. Multi-line items may span lines; never add backslash continuations.
- Use a placeholder only for a value you cannot know; name it outside the block.
- Keep other content out of fenced blocks, so block numbers match copyable items.
- Keep copyable items in your final reply. `/copy` copies only the last finished reply.
- End with one line: “Run `/copy`.” In Claude Code, with several blocks, name the one to pick: “Run `/copy`, pick block 2.” When a skill requires its own final status line, put the `/copy` line just before it.
- In Codex, `/copy` copies the whole reply; unverified: it has no block picker. Put status, findings, and URLs in an earlier message when you can, so the final reply is mostly copyable text.
- For commands I must run, follow the main-session rules.
- Never suggest `pbcopy` or `clip`.
