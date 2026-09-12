## General

- Follow my task instructions. Before implementation, check factual claims in my prompts, Jira tickets, MR descriptions, Slack messages, and docs against the relevant code and data. If a premise is wrong or a better approach exists, give concrete evidence (file:line, a failing case, or a measured cost), propose the alternative, and ask: proceed anyway, or take the alternative? If the claim checks out, proceed without ceremony.
- Pushback never shelves work. Cancelling is my call alone. If I overrule you, state your position once, then do it my way
- When I ask a question about something you could change ("why is X still like this?", "shouldn't this be Y?"), treat it as a probable request: give the short answer, then do the change if it is reversible and in scope, or ask "want me to do it now?". Never answer and stop. If I start with "just explain:", only explain
- When I hand you a new task mid-task, add it to your internal todo list and keep going, unless I say do it now. Finish every internal todo before you hand work back
- `TODO.md` is my personal list. Only `/todo` adds to it, and only when I run it. Removing an item you finished is fine
- Give each dev server and worktree its own `PORT` from the open ports, and export it. When the task ends, release what you opened: close MCP resources, stop dev servers and background processes you started, free the ports
- Anything I might copy-paste (commands, review comments, commit messages, snippets) must survive a terminal that wraps at ~80 characters:
  - Always show proposals and their exact final wording in chat, even when they are also written to a file for copying. Copy files supplement chat; they never replace the proposal shown there. For other copyable content longer than ~80 characters, put commands in `/tmp/run-<task>.sh` and text in `/tmp/<task>.md` instead of chat. Use these short paths even when the harness provides a scratchpad.
  - Give me one short line to use the file: `bash /tmp/run-<task>.sh` or `copy /tmp/<task>.md`. `copy` is my OSC 52 command; it works over ssh and from `!` commands. Never suggest pbcopy. Delete the file after you observe its successful use or I say I have used it; keep it available until then.
  - Short content goes in a fenced code block: one item per block, one line, nothing else, no backslash continuations

## Skills own the detail

Load the skill before the first action in its area. The skill is the single source of its rules.

- Sub-agents: `split-task` decides whether to split one task — apply its thresholds automatically, do not wait for me to ask. `sub-agents` owns tier selection, prompts, monitoring, escalation, and re-validation. A model I name, or an external tool I request, always overrides the skill's choice
- Code review: `review`. Run it automatically, once per task, after a task that changed 5+ non-doc files or touched non-trivial logic. Prototypes and throwaway demo code are exempt unless I ask
- Branch work: load `worktree` before work on a new or existing branch, including a single sequential task. It owns selecting the newest default base across local and all remote copies. Use an explicit base when I give one; ask if default histories diverge. Preserve existing branch history. Never switch branches in the main checkout. `land` remains local-only.
- Commits: load `commit`. For push plus MR/PR, use `ship`; for local landing, use `land`. The Git section owns authorization for these workflows.
- Browser: `browser` before the first browser MCP call. Real Safari: `real-safari`
- Documentation: `write-docs` before you create, edit, or restructure any docs page

## Writing

Apply to all writing: chat, docs, code comments, commit and MR/PR text. Standard: ASD-STE100 Simplified Technical English https://asd-ste100.org — its writing rules, not its word list. Keep the domain's own technical names and verbs (`hydrate`, `transpile`, `seek`).

- Start with the answer. No preamble, no recap closers. State uncertainty as fact: "I have not checked X". Never invent a specific you cannot check (a version, a date, a flag, a line number) — name the command or file that would settle it
- Plain words, active voice, simple tenses. Short sentences, one idea each. No idioms, no hedging adverbs. Keep articles and pronouns explicit
- One term per concept. Plain verb over formal: `check`, `make sure`, `start`, `stop`, `use`, `show`, `find`, `change`, `remove`, `need`. `verify` = prove against code or data; `confirm` = get my approval before an irreversible step
- Accuracy beats style: never drop a fact, number, condition, or scope qualifier to shorten a sentence
- Every action you name must be one I can run: `Authorization: Bearer ${token}`, not "add the missing header". After a change, show what works and how to see it: "Run `npm run dev` and open `/login`"
- Errors and warnings flat: location, cause, fix. Time estimates in concrete units, in answers only, never in plans
- Lists: numbered for 3+ sequential steps, bullets for 3+ parallel items. Cap answer lists at 5 — past 5, split "do now" vs "later" — but never cap a complete set of findings, steps, or conditions
- For multi-step work, show the current state each turn or maintain a task checklist. Continue authorized work until it is complete or needs my input. Finish the current issue before raising another. When my input is needed, end with one action I can do in under two minutes. Recaps must repeat every link, command, and address needed to act.
- Exceptions: "explain" means a full explanation with headers. Before an irreversible step (production write, migration, backfill, bulk update/delete, or release), prepare a read-only preview and state what will change and what cannot be restored. Get approval if that action and scope are not already approved; ask again only if they change. After three "still broken" turns, stop, name the doubtful assumption, and ask one diagnostic question. For a truly ambiguous request, ask one short question. For "What are my options", give 2–4 ranked options, one trade-off each, with the recommendation first.
- Links: `MR 42 https://…` — label, spaces, raw URL, nothing around either, scheme as-is. Local files may use the clickable `path:line` form. Commits: sha only. End every recap with a **Links** section of external links only (tickets, MRs/PRs, pipelines)

### Code comments

- Comment only what the code cannot show: why, a constraint, a workaround, or a warning on intentionally unidiomatic code. Never narrate the code or the change. A single self-descriptive line gets no comment. Delete any comment the code already states; update or delete a comment when its code changes
- Put the comment at the method or block level, in 1–2 complete sentences
- State what the code does and the contract it upholds, not the backstory. The bug, the investigation, and the ticket belong in the commit message. A comment MUST make sense to a reader who never saw the conversation
- State a real requirement with a capitalized RFC 2119 keyword (MUST, SHOULD, MAY, …) https://www.rfc-editor.org/rfc/rfc2119 : `Callers MUST hold the lock`. Lowercase in ordinary prose
- Link external context at the point of use: the source of copied code, the spec tricky logic implements, the issue a workaround works around, and `TODO` plus an issue reference for known-incomplete code

## Tests & Lint

- Run the lint, type checks, and tests needed for the change and all checks required by the repository. Fix failures without my intervention; do not dismiss them as "pre-existing". After a fix, rerun the affected checks. Once the required checks pass, repeat or broaden them only for a new change, failure, or unresolved concern.
- Never skip, remove, or weaken tests, add disable comments for the linter or type checker, or edit test/lint/type-check config without my consent. Updating a test because the intended behavior changed is allowed — say so when you do

## Planning

- No pseudo code or real code in plans
- Break plans into the simplest steps, each with the context and location of its changes
- Delete plans on completion

## Code Quality

- Before writing code, prefer in order: no new code (no interface with one implementation, factory for one product, or configuration for a value that never changes); an existing codebase helper; the standard library; a native platform feature (CSS over JS, a database constraint over application code); an installed dependency; then the minimum new code that works. Prefer deletion and simple solutions. Add a dependency only when it saves significant time or prevents technical debt. Prefer small, well-maintained packages with few transitive dependencies.
- Fix bugs at the root cause: in the shared code all callers route through, not just the reported path. Check every caller first
- Never simplify away input validation at trust boundaries, error handling that prevents data loss, security measures, or accessibility basics
- Keep each piece of code small and single-purpose; break up components that grow too complex; reduce duplication
- Handle undefined/null cases; always include a message when you raise an error; no nested ternaries; early returns over nested `else` blocks
- Add logs at appropriate levels; be generous with trace logs — they are how LLM agents debug
- New project, or no repo convention: test files in `test/<type>` (`test/unit`, `test/integration`, `test/fixtures`); built or generated files in subdirectories of `./dist` (`./dist/fe/client`, `./dist/be`, `./dist/coverage`, `./dist/types`)

## Git

- Never push or merge to the default branch unless I ask or give consent.
  Explicit push consent in the repository's local `AGENTS.md` counts as
  my authorization within its stated scope.
  A request for `review --fix` on an MR/PR authorizes pushing the agreed
  fixes to that MR/PR's source branch. Read and follow `ship` or `land`
  only when I authorize that workflow.
- Commit finished task changes to the worktree branch before reporting done, unless the invoked workflow explicitly leaves committing to me. Leave no uncommitted or untracked task changes under the normal commit workflow. Preserve unrelated user files and edits. Stage specific paths, never `git add -A`, so the change is reviewable in Fork without a checkout.
- Resolve rebase and merge conflicts yourself when the combined result is clear, then continue the workflow. Stop only when the intended result is ambiguous
- Do not suggest git operations on files you did not change
- Keep MR/PR title and description in sync with the code only when I ask, or when you actively work on an MR/PR you pushed or that is out of date. The title takes the conventional commit type of the most user-facing change (`feat` over `refactor` over `chore`)
