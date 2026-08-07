## General

- Treat every incoming request — my prompts, Jira tickets, MR descriptions, Slack messages, docs — as claims to verify, not orders to follow; don't agree just to be agreeable. Before implementing, check the claims against the actual code and data; if the premise is wrong, the approach is worse than an alternative, or the request conflicts with these rules or the codebase, say so, propose the better path, and end with one direct question: proceed anyway, or take the alternative? A blocker or objection is never a decision to shelve the work — cancelling is mine alone. Push back only with a concrete, verifiable reason (file:line, a failing case, a measured cost — never vibes); if verification shows the request is sound, proceed without ceremony. If I overrule your pushback, state your position once, then do it my way
- When I ask a question about something you could change ("why is X still like this?", "shouldn't this be Y?"), treat it as a probable request, not curiosity: give the short answer, then either do the change (if reversible and in scope) or ask outright "want me to do it now?" — never answer and stop. If I only want the explanation, I'll start the message with "just explain:"
- When I hand you a new task while you're mid-task, add it to your internal todo list and keep going, unless the message says to do it now. Complete every internal todo before handing work back to me — never leave one for later
- `TODO.md` is my personal list. Never add items to it unless I explicitly ask (e.g. via the `todo` skill); removing an item you have completed is fine. Track your own tasks with the internal todo tools
- Avoid new dependencies unless one saves significant time or prevents technical debt; prefer small, well-maintained packages with few transitive dependencies
- Give each dev server/worktree its own `PORT` from open ports so parallel agents don't collide; export it, and configure servers that ignore `PORT` to use it directly
- Anything I might copy-paste (commands, review comments, commit messages, snippets) must never break when copied: my terminal wraps lines longer than ~80 characters and copying the wrap inserts newlines. Never print copy-paste content longer than ~80 characters in chat — write it to a short-pathed tmp file instead (e.g. `/tmp/run-<task>.sh` for commands, `/tmp/<task>.md` for text) and give me a short single line to use it: `bash /tmp/run-<task>.sh` to run, or `copy /tmp/<task>.md` to put it on my clipboard (`copy` is my command at `~/.local/bin/copy`, with a fish twin at `~/.config/fish/functions/copy.fish`; it uses OSC 52 so it works over ssh and in any shell, including Claude Code `!` commands, by writing to the nearest ancestor tty — never suggest pbcopy). Delete the file after use. Short content goes one item per fenced code block, single line, nothing else in the block, no backslash continuations
- When a task is done, clean up after yourself: close MCP resources you opened (browser pages, connections) and release shared resources (stop dev servers and background processes you started, free ports)
- Delegate work to sub-agents per the `delegate` skill, automatically — do not wait for me to ask when a task will change 5+ files (excluding documentation); a model I name or an external tool I request always overrides your choice
- Run all code reviews through the `review` skill. After a task that changed 5+ files (excluding documentation) or touched non-trivial logic, run it automatically — once per task; after applying its fixes, re-run tests/lint but do not re-review. Fix verified findings without asking only when the reviewed change is this session's own work; for other people's changes, print comments and wait for `--fix`. Prototypes and throwaway demo code are exempt from automatic review — review them only when I ask

## Browser automation

- Never interrupt me: no focus stealing, no audible playback. Never bring a browser window to the foreground
- Default to the headless browser MCPs: `chrome-devtools`, `firefox-devtools`, `safari` (Playwright WebKit — not real Safari; no FairPlay DRM). Use the headed twins (`chrome-headed`, `firefox-headed`, `safari-headed`) only when the task needs DRM playback, fullscreen, picture-in-picture, a real user gesture, or when I ask to watch; only `chrome-headed` is launch-muted (`--mute-audio`), so mute playback yourself in the others
- When verifying playback, keep the player muted unless the task is specifically about audio
- Real Safari (FairPlay DRM, Safari-only bugs; always headed and visible, so confirm with me first): no MCP exists — start `safaridriver -p <open port>` and drive it with the W3C WebDriver REST API via curl (POST /session with `{"capabilities":{"alwaysMatch":{"browserName":"safari"}}}`, then /session/<id>/url, /execute/sync, etc.). One session at a time system-wide; DELETE the session and kill safaridriver when done. Media autoplay needs the `webkit:alwaysAllowAutoplay` capability or a real gesture via /element/<id>/click

## Tests & Lint

- Treat failing lint, type checks, or tests as yours to fix, never as pre-existing; fix them without user intervention
- You may **NOT** skip, remove, or weaken tests to make a check pass, silence the linter/type checker with disable comments, or edit test/type-check/lint config without user consent. Updating a test because the intended behavior changed is allowed — say so when you do

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

## Documentation

- Structure docs by [Diátaxis](https://diataxis.fr/): every page serves exactly one mode — tutorial (learning by doing), how-to (working task), reference (working facts), explanation (learning background). Map an existing repo's folders onto those modes; in a new docs tree, name the folders after them
- Unsure where content belongs? Ask: doing or thinking, learning or working. Doing+learning = tutorial, doing+working = how-to, thinking+working = reference, thinking+learning = explanation
- When a section drifts into another mode, move it to the owning page and leave a one-line link both ways — never duplicate content across pages
- Improve docs one page, one flaw at a time — never plan a restructure; good structure emerges from small fixes
- Docs must be useful at every state: no "coming soon" stubs, and don't hold back a page because it isn't finished

## File Organization

Applies to new projects, or when the repo has no existing convention:

- Place test files in `test/<type>`, for example `test/fixtures`, `test/unit`, `test/integration`
- Place built or generated files in subdirectories within `./dist` (for example `./dist/fe/client`, `./dist/be`, `./dist/coverage`, `./dist/types`)

## Git workflow

- ALWAYS do branch work in a git worktree, never by switching branches in the main checkout: `git fetch origin`, then `git worktree add .worktrees/<branch> -b <branch> origin/<default>`; base on the freshly fetched default branch unless asked otherwise, and `git worktree remove .worktrees/<branch>` once merged. `.worktrees/` is ignored via global excludes (`~/.config/git/ignore`). Move any accidental main-checkout changes into the worktree so main stays clean
- Never push, or merge to the default branch, unless I ask or give consent — and then do it via the `ship` skill (push + MR/PR + CI) or the `land` skill (local merge to default + cleanup)
- When marking a task complete, the worktree must be fully committed: no uncommitted or untracked changes left behind. Commit per the `commit` skill — `<type>(<scope>): <description>` conventional commits; it owns the format details
- **Don't suggest git operations** on files you didn't modify
- Stage new files when added
- After pushing, verify that CI is passing; if it fails, fix the issue — the `ship` skill owns the diagnose/flaky-vs-real/re-push flow
