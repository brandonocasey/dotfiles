## General

- Push back when I'm wrong; don't agree just to be agreeable
- Avoid new dependencies unless one saves significant time or prevents technical debt; prefer small, well-maintained packages with few transitive dependencies
- Give each dev server/worktree its own `PORT` from open ports so parallel agents don't collide; export it, and configure servers that ignore `PORT` to use it directly
- When a task is done, clean up after yourself: close MCP resources you opened (browser pages, connections) and release shared resources (stop dev servers and background processes you started, free ports)

## Tests & Lint

- Treat failing lint, type checks, or tests as yours to fix, never as pre-existing; fix them without user intervention
- You may **NOT** skip, remove, or modify tests, silence the linter/type checker with disable comments, or edit test/type-check/lint config without user consent

## Planning

- Never add time estimates, pseudo code, or real code to plans
- Break plans into the most simple and basic steps, each with the context and location of its changes
- Delete plans upon completion

## Code Quality

- Before writing new code, prefer in order: not building it at all (YAGNI: no interface with one implementation, no factory for one product, no config for a value that never changes), an existing helper in this codebase, the stdlib, a native platform feature (CSS over JS, DB constraint over app code), an already-installed dependency; only then write the minimum code that works; prefer deletion over addition, boring over clever
- Fix bugs at the root cause: put the fix in the shared code all callers route through, not just the path the report names; check every caller first
- Never simplify away input validation at trust boundaries, error handling that prevents data loss, security measures, or accessibility basics
- Keep each piece of code small and single-purpose so it can be tested and reused; break up components that take on too much complexity, and reduce duplication
- Handle undefined/null cases; always include a message when raising errors; avoid nested ternaries and unnecessary nested `else` blocks (use early returns)
- Comments: minimal, complete sentences, only context the code can't show (why, constraints, workarounds, warnings on intentionally unidiomatic code); never narrate the code or the change; update or delete comments when the code they describe changes
- Link external context at the point of use: copied code links its source, tricky logic links the spec/standard/docs it implements, workarounds reference the issue they work around, and known-incomplete implementations get `TODO` plus an issue reference
- Add logs at appropriate levels; be generous with trace logs — they're how LLM agents debug

## Writing

Apply to all writing: chat responses, documentation, code comments, and commit/PR/MR text. (Caps, state-restating, and pre-send rules adapted from https://github.com/aaddrick/attention-control)

- ELI5 everything: plain language, active voice, short sentences (max 20 words for instructions, 25 for explanations), one idea per sentence; instructions in imperative form ("Remove the cover"); no idioms or figurative phrases; keep summaries short
- Use vertical lists for multi-part text: numbered for 3+ sequential steps (one bounded action per step, no nested "and then"), bulleted for parallel items; cap lists at 5 items — past 5, split into "do now" vs "later"
- One term per concept, one meaning per term; never vary terminology for the same item
- Start with the answer; no preamble, no closing pleasantries; before sending, delete openers that announce what you're about to do, closers that recap or ask "anything else?", and hedging adverbs ("perhaps", "possibly") — state uncertainty as plain fact instead ("I have not checked X")
- Accuracy beats style: never drop a fact, condition, number, or scope qualifier to make a sentence shorter; when a rule fights the answer, the answer wins
- For multi-step work, restate state each turn ("Step 3 of 5 done: schema updated. Next: run the backfill") and end with one concrete next action
- Finish the current issue before raising a second one; offer tangents as one question at the end
- Recaps must be self-contained: repeat all relevant links, commands, and addresses (dev server, LAN, and test URLs) each time; never point the reader to an earlier message
- Every MR/PR, ticket, pipeline, or file you mention must be a clickable link (`https://…` or `file:line`); never name one without its link. Commits are the exception: reference them by sha only, never as links. Never format links as markdown (`[text](url)`) — use bare URLs or OSC 8 hyperlinks. End every recap with a **Links** section listing only the relevant external links (tickets, MRs/PRs, pipelines/CI jobs — not commits) — never a list of every file or URL mentioned

## File Organization

Applies to new projects, or when the repo has no existing convention:

- Place test files in `test/<type>`, for example `test/fixtures`, `test/unit`, `test/integration`
- Place built or generated files in subdirectories within `./dist` (for example `./dist/fe/client`, `./dist/be`, `./dist/coverage`, `./dist/types`)

## Git workflow

- Do branch work in a git worktree, never by switching branches in the main checkout: `git fetch origin`, then `git worktree add .worktrees/<branch> -b <branch> origin/<default>`; base on the freshly fetched default branch unless asked otherwise, and `git worktree remove .worktrees/<branch>` once merged. `.worktrees/` is ignored via global excludes (`~/.config/git/ignore`). Move any accidental main-checkout changes into the worktree so main stays clean
- **Don't suggest git operations** on files you didn't modify
- Stage new files when added
- **Commit format**: `<type>(<scope>): <description>` conventional commits — details in the `commit` skill
- After pushing, verify that CI is passing; if it fails, fix the issue — the `ship` skill owns the diagnose/flaky-vs-real/re-push flow
