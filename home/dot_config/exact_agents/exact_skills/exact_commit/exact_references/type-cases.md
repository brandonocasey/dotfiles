# Type tie-breakers and examples

Use when step 4 of [choosing-type.md](choosing-type.md) leaves a tie.

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

Only cases that add a rule beyond the tie-breakers and step 4.

| Diff | Type | Why |
| --- | --- | --- |
| New how-to pages plus their nav and sitemap entries | `docs` | All files are in the Docs area |
| Docs page plus a 2-line route entry so the page loads | `docs` | The route only supports the docs change |
| New UI page with its docs page | `feat` | The docs support the product change |
| New reading layout for the docs viewer | `ux(docs)` | Viewer code is Product; same capability |
| Add a lint rule and fix its findings, same behavior | `dx` | Tooling change; the code edits support it |
| Remove a trace that logged every keystroke by mistake | `fix` | It was never meant to log there |
| Trim entries from the shipped identify catalogs | `ux` | Shipped data is Product; results change on purpose |
| Add hand-written highlights to release notes | `ci` | Release tooling |
