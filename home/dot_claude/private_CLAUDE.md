## General

- Don't always agree with me, only agree when I'm correct
- Give very small and concise summaries if you need to summarize
- Always ELI5 everything in the dumbest, easiest to understand way: plain language, short sentences, no dense or overly compressed phrasing
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
- Write comments as complete sentences
- When you change code, update or delete the comments that describe it
- If code needs a comment to be understood, prefer rewriting it (better names/structure); struggling to write a clear comment means the code needs refactoring
- Comment intentionally unidiomatic code so a future reader doesn't "simplify" it back into a bug
- Link sources at the point of use: copied code gets a link to where it came from; tricky logic gets a link to the spec/standard/docs it implements
- Bug-fix workarounds reference the issue/bug they work around
- Mark known-incomplete implementations with `TODO` plus an issue reference

## Technical Writing (based on ASD-STE100 Simplified Technical English)

- Procedures: max 20 words per sentence, one instruction per sentence, imperative form ("Remove the cover"), notes give information only — never instructions
- Descriptions: max 25 words per sentence, one topic per sentence, one topic per paragraph, max 6 sentences per paragraph; introduce information gradually
- Active voice; passive only in descriptions when the actor is unknown
- Simple tenses only (present, past, future); no complex verb chains ("has been removed" → "was removed"); no "-ing" verb forms except in technical nouns
- Noun strings: max 3 words — break longer ones up with prepositions ("runway light connection resistance calibration" → "calibration of the resistance of the runway light connection")
- One term per concept, one meaning per term; never vary terminology for the same item
- Keep articles (the, a, this); no contractions; don't drop words to shorten sentences
- Use vertical lists for complex or multi-part text
- Safety instructions: risk word (WARNING/CAUTION) + clear command + why ("what happens if you don't")
- No semicolons; American English spelling

## File Organization

- Place test files in `test/<type>`, for example `test/fixtures`, `test/unit`, `test/integration`
- All built or generated files must be placed in subdirectories within `./dist` (for example `./dist/fe/client`, `./dist/be`, `./dist/coverage`, `./dist/types`)

## Git workflow

- Default branch: `main`
- Before starting work, fetch and use the newest version of the default branch (e.g. `git fetch origin && git checkout main && git pull`) rather than the local version, unless the user specifies otherwise
- Do branch work in a git worktree (`git worktree add .worktrees/<branch> -b <branch>`), never by switching branches in the main checkout; base on the default branch unless asked otherwise, and clean up with `git worktree remove .worktrees/<branch>` once merged. `.worktrees/` is ignored via global excludes (`~/.config/git/ignore`), so worktrees stay inside the repo without polluting `git status`
- If you've already made changes in the default branch's checkout before creating the worktree, bring those changes over to the worktree and revert them in the default branch's checkout so main stays clean
- **Commit format**: `<type>(<scope>): <description>` conventional commits — full rules in the `commit` skill; scope required by commitlint (@.config/commitlint.config.js)
- **Changelog**: Run `npm version <major|minor|patch>` to bump version and update CHANGELOG.md automatically
- **Prerelease workflow**: For prereleases, commit normally. When ready for final release, run `npm run changelog:all` to regenerate entire CHANGELOG.md which consolidates all commits (including prerelease commits) into a single release entry
- After pushing, verify that CI is passing; if it fails, fix the issue
