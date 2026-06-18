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

- All code should be written to do one chunk of functionality well so that it can be well tested and reused
- Reduce duplication and complexity as much as possible while still meeting specifications
- Handle undefined/null cases; provide explicit returns
- Avoid nested ternaries and yoda expressions
- Always provide error messages when raising errors
- No nested `else` blocks when unnecessary (use early returns)
- Components should be broken up when one component starts to take on too much complexity
- Comments: minimal — only add context the code can't show (why, constraints, workarounds) or untangle complicated code; never narrate the code or the change

## File Organization

- Place test files in `test/<type>`, for example `test/fixtures`, `test/unit`, `test/integration`
- All built or generated files must be placed in subdirectories within `./dist` (for example `./dist/fe/client`, `./dist/be`, `./dist/coverage`, `./dist/types`)

## Git workflow

- Default branch: `main`
- Do branch work in a git worktree (`git worktree add ../<dir> -b <branch>`), never by switching branches in the main checkout; base on the default branch unless asked otherwise, and clean up with `git worktree remove` once merged
- **Commit format**: `<type>(<scope>): <description>` conventional commits — full rules in @/Users/bcasey/.claude/commands/commit.md; scope required by commitlint (@.config/commitlint.config.js)
- **Changelog**: Run `npm version <major|minor|patch>` to bump version and update CHANGELOG.md automatically
- **Prerelease workflow**: For prereleases, commit normally. When ready for final release, run `npm run changelog:all` to regenerate entire CHANGELOG.md which consolidates all commits (including prerelease commits) into a single release entry