---
name: commit
description: >
  Create logical Conventional Commits and choose amend versus new. Use when
  committing changes, directly or through another workflow.
---

Optional argument: a target file or chunk. Commit only that target.

1. **Gather** — skip if you already know the context. Run `git status --short`,
   `git diff`, `git diff --staged`, and `git log --oneline -5`.
2. **Decide amend or new.** Amend only when HEAD is not pushed to any remote and the change relates
   directly to it. Never amend a pushed commit. Make a new commit when none exist,
   HEAD is pushed, or the change has a different purpose or is a distinct unit.
3. **Write the message** per the Format section below. Use no emojis and no attribution,
   and keep secrets out of it. When you amend, keep the existing message unless the purpose
   of the commit changed.
4. **Commit.** Stage each chunk explicitly, including new and untracked files. Stage only
   the target when the user gave one. When one file spans multiple logical changes, follow
   [partial-staging.md](references/partial-staging.md). Then run one of:
   - New commit: `git commit -m '<message>'`.
   - Amend, message unchanged: `git commit --amend -C HEAD`.
   - Amend, message changed (the commit's purpose changed): `git commit --amend -m '<message>'`.

   Fix the cause of any hook error and commit again. Never `--no-verify` a failing hook
   unless the user has said the failure is irrelevant to the change.

Keep one logical change together, including supporting tests and docs.
Split unrelated changes.

## Format

`<type>(<scope>): <description>` — lowercase, imperative, no period, under 50 characters.

- Types: a11y, build, ci, deps, docs, dx, feat, fix, i18n, perf, refactor,
  revert, security, test, ux
- Do not use `chore` or `style` unless the repo's conventions require them.
  Release and CLA bots may still write `chore`
- If the repo's commitlint `type-enum` or AGENTS.md lacks a type, map it:
  `ux` → `feat`; `a11y` and `i18n` → `fix` for a repair, else `feat`;
  `security` → `fix`; `deps` → `build(deps)`; `dx` → `build`; `refactor` →
  `chore`. Map before writing, so commitlint does not reject the message
- Choose the type per **Choosing the type** below
- The scope is optional. Include one when the repo's commitlint config requires it
- Repository conventions override these defaults: commitlint config, AGENTS.md,
  or CONTRIBUTING. They can require a ticket suffix or a longer header limit
- Mark a breaking change with `!`, such as `feat!:` or `fix(api)!:` (**Choosing the type** below)
- Keep the description minimal, with no filler, and make it say why the change happened
- Add a body only when it gives context the description cannot hold

## Choosing the type

Choose the type from the main purpose of the change. Supporting tests and docs
stay with that change and take its type. For a squash PR, consider the full diff.

- Product: `fix` repairs wrong behavior; `feat` adds a capability; `ux` changes
  intended behavior or appearance; `perf` improves performance with identical
  output; `refactor` preserves behavior. Use `revert` for an undo, `security`
  for closing an exploit, and `a11y` or `i18n` for accessibility or localization.
- Other areas: `docs`, `test`, `ci`, `build`, `deps`, or `dx` for developer
  tooling, including agent rules and skills. A docs-only PR is `docs`.
- Mark a breaking change with `!` and a `BREAKING CHANGE:` footer describing
  the required migration. Repository conventions take precedence.

When two types fit or the main purpose is unclear, read
[choosing-type.md](references/choosing-type.md). Read its linked examples only
when a tie remains; routine commits do not need either reference.

## Constraints

- Do not use the `-i` flag or `git add -p`: they are interactive and cannot run here
- Do not create an empty commit
- Write temporary files in the scratch directory (AGENTS.md, **Directories**),
  never `/tmp`: a multi-line message, used with `git commit -F <file>`, and the
  hunk patch from [partial-staging.md](references/partial-staging.md). Remove them after the commit succeeds.
