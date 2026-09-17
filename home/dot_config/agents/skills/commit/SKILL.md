---
name: commit
description: >
  Create logical Conventional Commits and choose amend versus new. Use when
  committing changes, directly or through another workflow.
---

Optional argument: a target file or chunk. Commit only that target.

1. **Gather** — skip if you already know the context. Run `git status --short`,
   `git diff`, `git diff --staged`, and `git log --oneline -5`.
2. **Decide amend or new.** Amend when HEAD is not pushed to any remote AND the change is
   directly related to HEAD. Amending a pushed commit forces a divergent history, so never
   do it. Make a new commit when there are no commits yet, when the change has a different
   purpose, when HEAD is already pushed, or when the change is a distinct unit.
3. **Write the message** per the Format section below. Use no emojis and no attribution,
   and keep secrets out of it. When you amend, keep the existing message unless the purpose
   of the commit changed.
4. **Commit.** Stage each chunk explicitly, including new and untracked files. Stage only
   the target when the user gave one. When one file spans two chunks, stage the first
   chunk's hunks non-interactively: `git diff -U0 -- <file> > <patch>`, delete the hunks
   that belong to the other chunk, then `git apply --cached --unidiff-zero <patch>`. Then
   run one of:
   - New commit: `git commit -m '<message>'`.
   - Amend, message unchanged: `git commit --amend -C HEAD`.
   - Amend, message changed (the commit's purpose changed): `git commit --amend -m '<message>'`.

   Fix the cause of any hook error and commit again. Never `--no-verify` a failing hook
   unless the user has said the failure is irrelevant to the change.

Split the commits by concern, by type, or by pattern. One commit is one reviewable idea.
Do not bundle a refactor with a feature, or a fix with docs.

## Format

`<type>(<scope>): <description>` — lowercase, imperative, no period, under 50 characters.

- Types: build, ci, docs, dx, feat, fix, perf, refactor, revert, style, test
- The scope is optional. Include one when the repo's commitlint config requires it
- The repo's own conventions override these defaults — the commitlint config, AGENTS.md, or
  CONTRIBUTING. An example is a required ticket suffix such as `[PUBS-1234]`, or a header
  limit longer than 50 characters
- Mark a breaking change as `feat!:` or `feat(api)!:`
- Keep the description minimal, with no filler, and make it say why the change happened
- Add a body only when it gives context the description cannot hold

## Constraints

- Push only with authorization under the global Git rules.
- Do not use the `-i` flag or `git add -p`: they are interactive and cannot run here
- Do not create an empty commit
- Write a multi-line message to a file in the scratch directory (AGENTS.md,
  **Directories**), never `/tmp`, and use `git commit -F <file>`. Remove the file
  after the commit succeeds.
