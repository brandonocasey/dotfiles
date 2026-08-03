---
name: commit
description: >
  Create a git commit: split the working tree into logical chunks, decide amend vs new,
  and write Conventional Commit messages. Use when the user says "commit", "commit this",
  "commit my changes", or invokes /commit. The land, ship, and repo-audit skills defer to
  it for chunking, message format, and the amend-vs-new decision.
---

Optional: target file/chunk only.

1. **Gather** (if context unknown): `git status --short`, `git diff -w`, `git log --oneline -5`
2. **Amend if**: HEAD not pushed to any remote AND directly related to HEAD (amending a pushed commit forces a divergent history). **New if**: no commits, different purpose, HEAD already pushed, or distinct unit
3. **Message**: no emojis, no attribution, skip secrets. Amending: keep message unless purpose changed
4. **Commit**: stage each chunk explicitly, including new/untracked files (only the target if param provided); `git commit --amend -C HEAD` or new commit; fix hook errors

Split commits by concern/type/pattern — one commit = one reviewable idea; don't bundle a refactor with a feature or a fix with docs.

## Format
`<type>(<scope>): <description>` - lowercase, imperative, no period, <50 chars
- Types: build, ci, docs, dx, feat, fix, perf, refactor, revert, style, test
- Scope: optional; include one when the repo's commitlint config requires it
- Breaking: `feat!:` or `feat(api)!:`
- Minimal, no filler, focus "why"
- Body: if adds context

Constraints: no push unless asked; no `-i` flag; no empty commits; use heredoc: `git commit -m "$(cat <<'EOF'...EOF)"`
