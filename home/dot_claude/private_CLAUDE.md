## General

- Don't always agree with me, only agree when I'm correct
- Give very small and concise summaries if you need to summarize
- **Don't suggest git operations** on files you didn't modify
- Use commands you have access to without asking
- Stage new files when added
- Always prefer not adding dependencies or adding a dependency with fewer of its own dependencies when possible
- Assume issues are not pre-existing. Always look into fixing them
- Give each dev server/worktree its own `PORT` from open ports so parallel agents don't collide; set it in the environment, and configure servers that don't honor `PORT` to use it directly

## Test & Lint considerations

- You may **NOT** skip, remove, or modify tests without user consent
- Failing linting, type checking, or tests is **ALWAYS** an issue and must be fixed without user intervention
- Never silence the linter/type checker with disable comments, nor edit test/type-check/lint config, without user consent

## Planning

- Never add time estimates for plans that you make
- Never add pseudo or real code for planning
- Break down plans into the most simple and basic steps
- Delete plans upon completion
- Give context and location of changes in all plans

## Logging

- Add appropriate trace/debug/info/error/warning logs; trace logs especially, for LLM debugging

## Code Quality

- Build each piece of code to do one thing well so it can be tested and reused; break up a component when it takes on too much complexity
- Reduce duplication and complexity as much as possible while still meeting specifications
- Handle undefined/null cases; provide explicit returns
- Avoid nested ternaries and yoda expressions
- Always provide error messages when raising errors
- No nested `else` blocks when unnecessary (use early returns)
- Comments: minimal — only add context the code can't show (why, constraints, workarounds) or untangle complicated code; never narrate the code or the change

## File Organization

- Place test files in `test/<type>`, for example `test/fixtures`, `test/unit`, `test/integration`
- All built or generated files must be placed in subdirectories within `./dist` (for example `./dist/fe/client`, `./dist/be`, `./dist/coverage`, `./dist/types`)

## Git workflow

- Default branch: `main`
- Do branch work in a git worktree (`git worktree add .worktrees/<branch> -b <branch>`), never by switching branches in the main checkout; base on the default branch unless asked otherwise, and clean up with `git worktree remove .worktrees/<branch>` once merged. `.worktrees/` is ignored via global excludes (`~/.config/git/ignore`), so worktrees stay inside the repo without polluting `git status`
- If you've already made changes in the default branch's checkout before creating the worktree, bring those changes over to the worktree and revert them in the default branch's checkout so main stays clean
- **Commit format**: `<type>(<scope>): <description>` conventional commits — full rules in the `commit` skill; scope required by commitlint (@.config/commitlint.config.js)
- **Changelog**: Run `npm version <major|minor|patch>` to bump version and update CHANGELOG.md automatically
- **Prerelease workflow**: For prereleases, commit normally. When ready for final release, run `npm run changelog:all` to regenerate entire CHANGELOG.md which consolidates all commits (including prerelease commits) into a single release entry

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
