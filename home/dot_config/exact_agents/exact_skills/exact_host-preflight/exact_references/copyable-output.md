# Copyable output

Read when preparing commands or text the user must copy.

I copy text with `/copy`. Claude Code and Codex both have it. Make it one step:

- Never write copy files. Put all copyable text in chat, however long.
- Ignore terminal width. Never wrap or shorten copyable text to fit.
- Put each copyable item in its own fenced block, holding only that item: no shell prompts like `$` and no comments. Keep a leading `!` meant for my prompt. Multi-line items may span lines; never add backslash continuations.
- Hand me at most one command per reply. When I must run two or more, put them all in one self-deleting scratch script, test it, and hand me only `! sh <script>`. This limit spans replies: while a script you handed me has not run, merge new steps into it and hand it again; never hand a second script. When a shell write of the script is blocked, write it with the file-write tool. A denial never permits a list of commands instead.
- Use a placeholder only for a value you cannot know; name it outside the block.
- Keep other content out of fenced blocks, so block numbers match copyable items.
- Keep copyable items in your final reply. `/copy` copies only the last finished reply.
- End with one line: “Run `/copy`.” In Claude Code, with several blocks, name the one to pick: “Run `/copy`, pick block 2.” When a skill requires its own final status line, put the `/copy` line just before it.
- In Codex, `/copy` copies the whole reply; unverified: it has no block picker. Put status, findings, and URLs in an earlier message when you can, so the final reply is mostly copyable text.
- Never suggest `pbcopy` or `clip`.
