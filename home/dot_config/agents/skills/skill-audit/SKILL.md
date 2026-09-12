---
disable-model-invocation: true
name: skill-audit
description: >
  Renamed to llm-setup-audit; kept only as an alias so /skill-audit still works.
  Use only when the user invokes /skill-audit.
---

Read [llm-setup-audit](../llm-setup-audit/SKILL.md), resolved relative to this
file, and follow it with the user's arguments unchanged. It owns the audit flow.
This alias does not require a harness-specific skill invocation tool.
