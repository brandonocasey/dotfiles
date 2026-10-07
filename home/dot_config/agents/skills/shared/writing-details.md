# Conditional writing rules

- Link every MR/PR, ticket, pipeline, job, build, preview URL, doc page, and other web resource referred to by ID, title, or phrase (“the MR”, “the pull request”). Link it in each reply, even if linked before. Never give a bare ID such as `!123` or `PUBS-1234`; in tables, put the URL in the row. Format: label then raw URL; local references use `path:line`, commits use sha.
- For “eli5”, list real events in order, then their effect in one sentence. Avoid metaphors and unexplained code names.
- Before multi-step status updates, change recaps, or tracking work with 3+ deliverable steps or work spanning turns, read [work-output.md](work-output.md). Sub-agent handbacks skip it unless requested.
- Before PR descriptions, read [writing.md](../ship/references/writing.md); review comments, [output.md](../review/references/output.md); tickets, `mr-ticket`; documentation, `write-docs`. Repository templates win.
