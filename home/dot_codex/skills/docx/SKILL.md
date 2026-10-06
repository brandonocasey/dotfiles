---
name: docx
description: "Use for any Word document or template task, including .docx/.dotx inputs or outputs. For format-unspecified documents, prefer an available dedicated document/page skill, subject to destination authorization. Excludes PDFs, spreadsheets, Google Docs, and unrelated coding."
---

Find the installed upstream skill at
`~/.config/agents/skills/synced/*/docx/SKILL.md` and read it before
performing the task. Its full scope, examples, and procedures still apply.
Resolve its relative paths against the upstream skill directory.

If multiple accounts match, use the account established for this task;
otherwise ask which account's skill to use. If none matches, report the
missing skill; do not install one or substitute a different output format.
Preserve the requested format and authorized destination.
