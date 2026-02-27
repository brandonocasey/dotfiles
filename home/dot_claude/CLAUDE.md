## General

- Don't always agree with me, only agree when I'm correct
- Give very small and concise summaries if you need to summarize
- **Don't suggest git operations** on files you didn't modify
- Don't ask to use specific commands that you don't have access to. Try to use commands that you already have access to without asking
- Stage new files when added
- **Use relative imports** - No path aliases (for example `../../shared/log` not `@/shared/log`)
- Always prefer not adding dependencies or adding a dependency with fewer of its own dependencies when possible
- Assume issues are not pre-existing. Always look into fixing them

## Test & Lint considerations

- You may **NOT** skip, remove, or modify tests without user consent
- Failing linting, type checking, or tests is **ALWAYS** an issue and must be fixed without user intervention.
- Never modify test, typescript, or linting configuration without user consent
- Never use `any`, `@ts-ignore`, or other linter/type checking disable comments without user consent.

## Planning

- Never add time estimates for plans that you make
- Never add pseudo or real code for planning
- Break down plans into the most simple and basic steps
- Delete plans upon completion
- Give context and location of changes in all plans

## Logging

- Always include appropriate trace, debug, info, error, and warning logs.
- Trace level logs are especially important and should always be added when possible for LLM debugging

## Code Quality

- All code should be written to do one chunk of functionality well so that it can be well tested and reused
- Reduce duplication and complexity as much as possible while still meeting specifications
- Follow strict TypeScript settings: handle undefined/null from indexed access, provide explicit returns
- Prefer `for...of` loops over `.forEach()` methods
- Avoid nested ternaries and yoda expressions
- Always provide error messages in Error constructors
- No nested `else` blocks when unnecessary (use early returns)
- Components should be broken up when one component starts to take on too much complexity

## File Organization

- Place test files in `test/<type>`, for example `test/fixtures`, `test/unit`, `test/integration`
- All built or generated files must be placed in subdirectories within `./dist` (for example `./dist/fe/client`, `./dist/be`, `./dist/coverage`, `./dist/types`)

## Git workflow

- Default branch: `main`
- VCS integration enabled for git operations

- **Commit format**: Use conventional commits as defined in @/Users/bcasey/.claude/commands/commit.md
- **Commit types**: build, ci, docs, dx, feat, fix, perf, refactor, revert, style, test
- **Commit scopes**: Use scopes defined in @.config/commitlint.config.js (core, deps, config, docs, test)
- **Commit message format**: `<type>(<scope>): <description>` (scope is required by commitlint)
- **Changelog**: Run `npm version <major|minor|patch>` to bump version and update CHANGELOG.md automatically
- **Prerelease workflow**: For prereleases, commit normally. When ready for final release, run `npm run changelog:all` to regenerate entire CHANGELOG.md which consolidates all commits (including prerelease commits) into a single release entry

@RTK.md
