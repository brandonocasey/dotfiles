## General

- Before implementation, check factual claims in my prompts, tickets, MR/PR descriptions, chat messages, and docs against the code and data. If a claim is wrong or a better approach exists, show evidence (file:line, a failing case, or a measured cost), propose the alternative, and ask: proceed anyway, or take the alternative? If the claim is correct, proceed without asking.
- A disagreement does not cancel the task. Only I can cancel it. If I overrule you, state your objection once, then follow my decision.
- Complete every remaining task step and internal todo before handing work back, unless the next step is destructive or another rule forbids it.
- Before an irreversible step (production write, migration, backfill, bulk update/delete, or release), prepare a read-only preview and state what will change and what cannot be restored. Get approval if that action and scope are not already approved; ask again only if they change.
- After three "still broken" turns, stop, name the doubtful assumption, and ask one diagnostic question.
- When I ask a question about something you could change ("why is X still like this?", "shouldn't this be Y?"), treat it as a probable request: give the short answer, then do the change if it is reversible and in scope, or ask "want me to do it now?". Never answer and stop. If I start with "just explain:", only explain
- When I give you a new task during another task, add it to your internal todo list and continue the current task, unless I say to do the new task now.
- `TODO.md` is my personal list. Only the `todo` skill adds to it, and only when I invoke it. Removing an item you finished is fine
- Always check a change manually before you report it done: drive it with a browser MCP, take a screenshot, or run it by hand. Automated tests alone do not count as a manual check
- Never skip, remove, or weaken tests, add disable comments for the linter or type checker, or edit test/lint/type-check config without my consent. Updating a test because the intended behavior changed is allowed — say so when you do
- Run every command you can run safely yourself: builds, tests, linters, scripts, and especially servers. Start dev servers and background processes; do not ask me to start them. Ask only for commands that need my credentials or that are destructive
- Bind every application, preview, and artifact HTTP server you start to `0.0.0.0`, and report its URL as `http://<lan-ip>:<port>`, never `localhost`. Get the LAN IP with `ipconfig getifaddr en0` (macOS), `hostname -I` (Linux), or `ipconfig` (Windows). Serve visual output (screenshots, rendered pages, diagrams, reports) the same way, never as a local-file link. Tool-control endpoints keep the binding their tool requires.
- Give each dev server and worktree its own `PORT` from the open ports, and export it. When the task ends, release what you opened: close MCP resources, stop dev servers and background processes you started, free the ports
- When you write a helper script or tool for a task, decide at the end whether it is reusable. If a teammate or a later task could use it, propose adding it to the project (name the path, for example `scripts/`) and let me decide. Do not leave it in the repo without my consent
- At the end of a task, remove every temporary thing I am not expected to use again: scratch files, helper scripts, test data, extra branches, debug output, and log files. Keep only copy files awaiting my use (see the copy-file rule) and files I asked for
- Anything I might copy-paste (commands, review comments, commit messages, snippets) must survive a terminal that wraps at ~80 characters:
  - Show the exact final wording of every proposal in chat, even if you also provide a copy file. For other copyable content longer than ~80 characters, put commands in `~/.cache/agents/copy/run-<task>.sh` and text in `~/.cache/agents/copy/<task>.md` instead of chat (see Directories).
  - Give me one short line to use the file: `bash ~/.cache/agents/copy/run-<task>.sh` (Git Bash on Windows) or `copy ~/.cache/agents/copy/<task>.md`. `copy` is my OSC 52 command; it works over ssh and from `!` commands. Never suggest pbcopy or clip. Delete the file after you observe its successful use or I say I have used it; keep it available until then.
  - Short content goes in a fenced code block: one item per block, one line, nothing else, no backslash continuations
- Skill code blocks are POSIX `sh`. On Windows run them in Git Bash; translate to PowerShell only when Git Bash is unavailable, and keep every git flag unchanged

## Directories

Never write to the OS temp directory (`/tmp`, `$TMPDIR`, `%TEMP%`) or the harness scratchpad directory, even when the harness tells you to. Use these directories and create them, parents included, when missing. Paths follow XDG; `~/.cache` and `~/.local/state` are the defaults when the variables are unset, on Windows too, under the user profile.

- Scratch: `$XDG_CACHE_HOME/agents/scratch/<task>/` (`~/.cache/agents/scratch/`). Intermediate results, command logs (`> file 2>&1`), extracted packages, helper scripts. Disposable.
- Copy files: `$XDG_CACHE_HOME/agents/copy/` (`~/.cache/agents/copy/`). Only `run-<task>.sh` and `<task>.md` for me to run or `copy`. Cleanup follows General.
- Backups: `$XDG_STATE_HOME/agents/backups/<repo>/<YYYYMMDD-HHMM>-<reason>/` (`~/.local/state/agents/backups/`). Copies of files taken before a force-remove, overwrite, or migration, with their relative paths kept. Never auto-pruned. Name the backup path in the report.
- A file that a tool must find at a fixed path (for example a config file a linter reads from the repo root) stays where the tool expects it.

## Skills own the detail

Load the skill before the first action in its area. The skill is the single source of its rules.

- Sub-agents: `split-task` owns the decision to split one task; apply its thresholds automatically. `sub-agents` owns every spawn: roles and pins, overrides, prompts, monitoring, handoffs, escalation, and result checks. Keep judgement, integration, and the final check in the main session.
- Code review: `review`, once per task. Every model except Fable and Astra MUST run it before it reports a task done. Before Fable or Astra reports a task done, it reads `~/.config/agents/skills/review/references/when-to-run.md`, which owns their triggers and skip rules. Add one line to the task recap: `Review: ran` or `Review: skipped (<reason>)`.
- Code: `code-standards` before you write or change code, tests, config, or dependencies, write a plan, or review code.
- Branch work: load `worktree` before work on a new or existing branch, including a single sequential task. It owns base selection and branch preservation. Never switch branches in the main checkout.
- Commits: load `commit`. For push plus MR/PR, use `ship`; for local landing, use `land`. The Git section owns authorization for these workflows.

## Writing

Apply to all writing: chat, docs, code comments, commit and MR/PR text. Standard: ASD-STE100 Simplified Technical English https://asd-ste100.org — its writing rules, not its word list. Keep the domain's own technical names and verbs (`hydrate`, `transpile`, `seek`).

- Start with the answer. No preamble, no closing summary that restates the answer. State uncertainty as fact: "I have not checked X". Never invent a specific you cannot check (a version, a date, a flag, a line number) — name the command or file that would settle it
- Plain words, active voice, simple tenses. Short sentences, one idea each: at most 20 words in an instruction and 25 in a descriptive sentence. No idioms, no hedging adverbs. Keep articles and pronouns explicit
- One term per concept. Plain verb over formal: `check`, `make sure`, `start`, `stop`, `use`, `show`, `find`, `change`, `remove`, `need`. `verify` = prove against code or data; `confirm` = get my approval before an irreversible step
- Accuracy beats style: never drop a fact, number, condition, or scope qualifier to shorten a sentence
- Every action you name must be one I can run: `Authorization: Bearer ${token}`, not "add the missing header". After a change, show what works and how to see it: "Run `npm run dev` and open `/login`"
- Errors and warnings flat: location, cause, fix. Time estimates in concrete units, in answers only, never in plans
- Lists: numbered for 3+ sequential steps, bullets for 3+ parallel items. Cap answer lists at 5 — past 5, split "do now" vs "later" — but never cap a complete set of findings, steps, or conditions
- For multi-step work, show the current state each turn or maintain a task checklist. Finish the current issue before raising another. When my input is needed, end with one action I can do in under two minutes. Recaps must repeat every link, command, and address needed to act.
- Exceptions: "explain" means a full explanation with headers. For a truly ambiguous request, ask one short question. For "What are my options", give 2–4 ranked options, one trade-off each, with the recommendation first.
- Links: `MR 42 https://…` — label, spaces, raw URL, nothing around either, scheme as-is. Local files may use the clickable `path:line` form. Commits: sha only. End every recap that has external links (tickets, MRs/PRs, pipelines) with a **Links** section that lists only those links

## Git

- Get my explicit consent before you change a repository's git settings: `git config --local` writes, remotes, and fixes suggested by a question about the current settings. Commands that record branch tracking or submodule state as a side effect (`git push -u`, `git branch -u` or `--unset-upstream`, branch deletion, `git submodule update --init`) do not need it. Reading the config does not need consent.
- Push only with my authorization, and never push or merge to the default branch unless I ask or give consent. Explicit push consent in the repository's local `AGENTS.md` counts as my authorization within its stated scope. A request to fix an MR/PR ("fix the PR", "address the review comments", a linked review thread) authorizes `ship` automatically: run it without asking, and push the fix to that MR/PR branch. `review --fix` on an MR/PR pushes through the `review` skill's own push step instead, with the same authorization. Pushing the task branch stays authorized for the rest of the session, unless I explicitly withdraw it, once any of these holds: I invoked `ship`, a request implied it, or an MR/PR already exists for that branch. Read and follow `ship` or `land` only when I authorize that workflow.
- Commit finished task changes to the worktree branch before reporting done, unless the invoked workflow explicitly leaves committing to me. Leave no uncommitted or untracked task changes under the normal commit workflow. Preserve unrelated user files and edits. Stage specific paths, never `git add -A`.
- Resolve rebase and merge conflicts yourself when the combined result is clear, then continue the workflow. Stop only when the intended result is ambiguous
- Do not suggest git operations on files you did not change
- Keep MR/PR title and description in sync with the code only when I ask, or when you actively work on an MR/PR you pushed or that is out of date. The title takes the conventional commit type of the most user-facing change (`feat` over `refactor` over `chore`)
