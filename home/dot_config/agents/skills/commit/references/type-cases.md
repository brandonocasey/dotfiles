# Type tie-breakers and examples

Use with **Choosing the type** in [SKILL.md](../SKILL.md), step 4.

## Tie-breakers

- `feat` versus `ux`: ask "What can users do now that they could not do
  before?" Name a thing → `feat`. Same things, easier or nicer → `ux`.
  A redesign, a new layout, merged panels, moved controls, and clearer
  messages are `ux`.
- `fix` versus `ux`: a fix repairs something that did not work as
  intended. A ux change alters something that worked as intended.
- `a11y` and `i18n` take precedence over `fix`, `feat`, and `ux`, because
  their readers look for them by name. The code changes they need do not
  change the type. Copy changes in the source language
  are `ux`, not `i18n`.
- `security` takes precedence over `fix`. A defect with no attacker in
  the story is `fix`.
- CSS is Product. An intended visual change is `ux`, a visual defect
  repair is `fix`.
- Formatting-only changes (whitespace, import order, a formatter run) are
  `refactor`.
- A rename that users see (CLI flag, command, route, UI label) is `ux`,
  or `ux!` when the old name stops working. A rename in code only is
  `refactor`.
- Moving, splitting, deduplicating, or centralizing code is `refactor`,
  even when it touches many files. Removing dead code is `refactor`.
- Metadata that only affects search ranking (meta descriptions, structured
  data, product-page sitemap entries) is `ux` when the text a person sees
  changes, else `refactor`. Something programs or agents act on is `feat`:
  a new API, MCP tool, well-known file, `auth.md`, or discovery `Link`
  header.
- A change gated behind a flag or beta is typed as if the flag were on.
  Releasing a beta feature to everyone is `feat`. Moving a feature behind
  a flag or beta is `ux`.
- Restoring a look or behavior that a recent change broke is `fix`, and
  the body names the commit that broke it.
- Removing a capability on purpose is `ux`, or `ux!` when users or
  scripts must change something.
- Shorter labels, tighter spacing, decluttered screens, clearer messages,
  and better diagnostics are `ux` when the old version worked as intended.
- A change to machine-readable output (JSON fields, exit codes, file
  layout) that scripts read is `feat` when it adds and `ux!` when it
  changes or removes.

## Examples

| Diff | Type | Why |
| --- | --- | --- |
| New how-to pages plus their nav and sitemap entries | `docs` | All files are in the Docs area |
| Docs page plus a 2-line route entry so the page loads | `docs` | The route only supports the docs change |
| New UI page with its docs page | `feat` | The docs support the product change |
| New reading layout for the docs viewer | `ux(docs)` | Viewer code is Product; same capability |
| Move brand assets into one module, same output | `refactor` | Behavior and output are identical |
| Redesign the home page layout | `ux` | Same capabilities, changed look |
| Merge card drawers into the card | `ux` | Same capabilities, changed layout |
| Add a file checksum page | `feat` | Users can do something new |
| Button overlaps text on phones | `fix` | Layout went against the design |
| Add labels so screen readers name the buttons | `a11y` | Main purpose is assistive access |
| Add a Spanish translation | `i18n` | Locale files only |
| Escape file names before HTML output | `security` | Closes an XSS path |
| Rename CLI flag `--out` to `--output`, old flag removed | `ux!` | Users must change their scripts |
| Routine crate bump | `deps` | Only dependency versions changed |
| Bump a shipped crate for a reachable CVE | `security(deps)` | Fixes an advisory in the product |
| Repair a failing release workflow | `ci` | Only CI files changed |
| Raise a CI bundle-size budget | `ci` | The budget runs only in CI |
| Add a lint rule and fix its findings, same behavior | `dx` | Tooling change; the code edits support it |
| Run the formatter over the repo | `refactor` | Same behavior, formatting only |
| Remove a trace that logged every keystroke by mistake | `fix` | It was never meant to log there |
| Shorten a download button label | `ux` | The old label worked as intended |
| Restore the desktop layout a redesign broke | `fix` | Repairs a regression |
| Localize settings labels that showed in English | `i18n` | Translation work, precedence over `fix` |
| Bound allocations from untrusted ROM headers | `security` | Closes a denial-of-service path |
| Release the Identify tool from beta to everyone | `feat` | Everyone gets a new capability |
| Trim entries from the shipped identify catalogs | `ux` | Shipped data is Product; results change on purpose |
| Add hand-written highlights to release notes | `ci` | Release tooling |
| Cache compiler output to speed up CI | `ci` | CI speed is not `perf` |
| Faster checksum, byte-identical output | `perf` | Only speed changed |
