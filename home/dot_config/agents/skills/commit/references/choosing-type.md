# Detailed commit type selection

Read when the compact rules in [SKILL.md](../SKILL.md) leave the type unclear.

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

2. **Mixed areas:** keep one logical change together, including supporting
   tests and docs. Split unrelated changes. For a commit or squash PR title,
   find the main purpose: the change that would remain if you removed the rest. Use the
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

   Read [type-cases.md](type-cases.md) when two rows could fit,
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
