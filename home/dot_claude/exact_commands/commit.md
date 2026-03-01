---
description: Create git commit
---

Optional: target file/chunk only.

1. **Gather** (if context unknown): `git status --short`, `git diff -w`, `git log --oneline -5`
2. **Amend if**: not pushed to main AND directly related to HEAD. **New if**: no commits, different purpose, pushed to main, or distinct unit
3. **Message**: no emojis, no attribution, skip secrets. Amending: keep message unless purpose changed
4. **Commit**: stage target if param provided; `git commit --amend -C HEAD` or new commit; fix hook errors

Split commits by concern/type/pattern.

## Format
`<type>(<scope>): <description>` - lowercase, imperative, no period, <50 chars
- Types: build, ci, docs, dx, feat, fix, perf, refactor, revert, style, test
- Scope: optional
- Breaking: `feat!:` or `feat(api)!:`
- Minimal, no filler, focus "why"
- Body: if adds context

Constraints: no push unless asked; no `-i` flag; no empty commits; use heredoc: `git commit -m "$(cat <<'EOF'...EOF)"`
