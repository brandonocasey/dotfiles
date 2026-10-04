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
   the target when the user gave one. When one file spans two chunks, stage the first
   chunk's hunks non-interactively: `git diff -U0 -- <file> > <patch>`, delete the hunks
   that belong to the other chunk, then `git apply --cached --unidiff-zero <patch>`. Then
   run one of:
   - New commit: `git commit -m '<message>'`.
   - Amend, message unchanged: `git commit --amend -C HEAD`.
   - Amend, message changed (the commit's purpose changed): `git commit --amend -m '<message>'`.

   Fix the cause of any hook error and commit again. Never `--no-verify` a failing hook
   unless the user has said the failure is irrelevant to the change.

Split by concern, type, or pattern. One commit is one reviewable idea. Do not
bundle a refactor with a feature, or a fix with docs.

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
- Mark a breaking change with `!`, such as `feat!:` or `fix(api)!:` (**Choosing the type**, step 5)
- Keep the description minimal, with no filler, and make it say why the change happened
- Add a body only when it gives context the description cannot hold

## Choosing the type

The type says what the change does, not how important it is. Changelogs and
version tools read it. Semver tools bump the minor version for `feat` and the
patch version for other release types. A wrong `feat` misleads users and
inflates versions. A wrong internal type hides a real change from users.

Follow these steps for each commit. For a PR title, use the whole diff.

1. **Classify each changed file** from `git diff --stat`. Generated files
   (typegen output, snapshots) take the area of the file that caused them.
   Tests that cover a change in the same diff take that change's area.
   Review-only files (PR screenshots, prototypes, scratch notes) do not count.
   Code that renders docs (a docs viewer, its layout, its search) is Product.

   | Area | Files |
   | --- | --- |
   | Product | Code, styles (including CSS), assets, UI text, translations, config defaults, CLI output, published endpoints and metadata, data files that ship (catalogs, databases, schemas, presets), and hosting config that changes what users get (headers, redirects, edge functions, service workers) |
   | Docs | Docs pages, README, guides, examples, code comments, docstrings, package descriptions and keywords, and the nav, sitemap, or `llms.txt` entries that list docs pages |
   | Tests | Tests, fixtures, and test helpers with no product change in the diff |
   | CI | CI workflows, CI actions, checks that run only in CI (budgets, thresholds), release tooling (release workflows, changelog scripts, release config), and commit rules (commitlint config, Dependabot config) |
   | Build | Build scripts, bundler and compiler config, packaging, Dockerfiles, vendored third-party sources and their refresh scripts |
   | Deps | Dependency versions in manifests and their lockfile changes |
   | Tooling | Lint and formatter config, git hooks, editor config, agent instructions (`AGENTS.md`, skills), local dev scripts |

2. **Mixed areas:** split the commit by area when you can. One reviewable idea
   per commit. For one commit or a squash PR title that cannot split, find the
   main purpose: the change that would remain if you removed the rest. Use the
   area of the main purpose in step 3 or 4. Docs, tests, deps, and build
   changes that support a product change take the product type. A product
   change that only supports a docs, test, or tooling change does not make it
   `feat` or `ux`.

3. **Main purpose is not Product:** use the area type, even for a fix in
   that area. Docs → `docs`, Tests → `test`, CI → `ci`, Build → `build`,
   Deps → `deps`, Tooling → `dx`. A docs typo fix is `docs`. A flaky test fix
   is `test`. A broken workflow fix is `ci`. A faster CI job is `ci` and a
   faster build is `build`; `perf` is only for the product. A `.gitignore`
   or license-year change is `dx`.
   - Exception: a dependency bump that fixes a published advisory is
     `security(deps)` when the vulnerable code ships in the product. It is
     `deps` when the dependency is dev-only or the vulnerable path is
     unreachable. Name the advisory ID in the body.

4. **Main purpose is Product:** pick the first row that is true for a person,
   script, or program that uses the shipped product:

   | Question | Type |
   | --- | --- |
   | Does it undo an earlier commit? | `revert` |
   | Does it close a way to read, change, or deny data or service without permission (injection, XSS, path traversal, auth bypass, unsafe defaults)? | `security` |
   | Is the main purpose access for people with disabilities (screen readers, keyboard-only use, focus order, contrast, reduced motion, target size)? | `a11y` |
   | Is the main purpose localization: text shown in the wrong language, locale files, locale-aware formatting, or a new language? Wrapping strings in the localizer counts. | `i18n` |
   | Did behavior go against the intended design, the docs, or a reasonable expectation, and does it now match? | `fix` |
   | Is all output identical, and only speed, memory, or size better? | `perf` |
   | Can users do something they could not do before (a new command, flag, format, page, tool, setting, API, or endpoint)? | `feat` |
   | Does an existing capability look, read, or behave differently on purpose (layout, flow, visuals, copy, defaults, feedback, messages)? | `ux` |
   | Is all behavior and output identical? | `refactor` |

   Read [type-cases.md](references/type-cases.md) when two rows could fit,
   and for renames, removals, flags or betas, restored behavior, CSS,
   formatting, moved code, search metadata, or machine-readable output.
   It holds the tie-breakers and worked examples.

5. **Breaking change:** add `!` after the type or scope, on any type, when a
   user must change something to keep working: a removed or renamed flag,
   command, option, API, route, config key, file path, output format, or exit
   code. Add a `BREAKING CHANGE: <what to change>` footer.

6. **Check the result.** Answer each question; on a no, start again at step 1.
   - Would a user who reads the header in the release notes agree with it?
   - For `feat`: does the description name the new thing a user gets?
     "Centralize", "reorganize", "clean up", or "split" means `refactor`.
     "Improve", "redesign", "simplify", "polish", "refresh", "tidy",
     "declutter", "tune", "align", "refine", or "clarify" means `ux`.
   - For `fix`: can you state the old wrong behavior in one sentence?
   - For `security`: can you state who could exploit it and how?
   - Did the area decide the type, not the scope? The scope only names the
     part of the repo. `feat(docs)` with only Docs files is wrong; use `docs`.
     `feat(docs)` that adds a search box to the docs viewer is correct.

## Constraints

- Do not use the `-i` flag or `git add -p`: they are interactive and cannot run here
- Do not create an empty commit
- Write temporary files in the scratch directory (AGENTS.md, **Directories**),
  never `/tmp`: a multi-line message, used with `git commit -F <file>`, and the
  hunk `<patch>` from workflow step 4 (**Commit**). Remove them after the commit succeeds.
