# Conditional writing rules

- Link every web resource (also doc pages, builds, previews) referred to by ID, title, or phrase (“the MR”). Exception: link a pipeline or CI job only when it failed or matters to the point; otherwise state its status in words. In tables, put the URL in the row. Format: label then raw URL; local references use `path:line`, commits use sha. In each turn's final reply, give the URL of each web resource mentioned, plus the main MR/PR once one exists.
- For “eli5”, list real events in order, then their effect in one sentence. Avoid metaphors and unexplained code names.
- Before multi-step status updates, change recaps, or tracking work with 3+ deliverable steps or work spanning turns, read [work-output.md](work-output.md). Sub-agent handbacks skip it unless requested.
- Before PR descriptions, read [ship/SKILL.md](../ship/SKILL.md) step 3; review comments, [output.md](../review/references/output.md); tickets, `mr-ticket`; documentation, `write-docs`. Repository templates win.
- Drafts (messages, tickets, replies): verify each claim first, leave no TODO placeholders, and label unverified items. Keep messages and replies to ≤5 sentences or bullets; ticket descriptions follow mr-ticket.
