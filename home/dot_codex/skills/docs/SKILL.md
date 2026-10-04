---
name: docs
description: Create or edit a hosted document only when explicitly invoked.
---

Use only for an explicitly requested hosted destination, including one already
established in this conversation. Preserve the requested format and destination.

Find the installed upstream skill at
`~/.config/agents/skills/synced/*/docs/SKILL.md` and read it before the
first connector call. If more than one matches, ask which account's skill to use.
If none exists, report that the synced skill is unavailable; do not install one
or substitute a hosted destination.
