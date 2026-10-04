## General

- Before implementation, check factual claims in prompts, tickets, MR/PR descriptions, chats, and docs against code and data. For a wrong claim that changes the result, show file:line, a failing case, or measured cost, then ask: proceed anyway, or take the alternative? For a wrong claim that does not change the result, state the correction in one line and proceed. For a merely better approach, name it with its cost and proceed as asked. Otherwise proceed.
- Only I can cancel the task. If I overrule your objection, state it once, then follow my decision.
- Complete every task step and internal todo before handing back, unless the next step is destructive or another rule forbids it.
- In a sub-agent, do only what the prompt assigns. Skip review, commits, cleanup, and recaps unless the prompt asks for them.
- Before irreversible work (production writes, migrations, backfills, bulk updates/deletes, releases), show a read-only preview. State what changes and what cannot be restored. Get approval unless that action and scope are already approved; ask again only if they change.
- After three “still broken” turns, stop, name the doubtful assumption, and ask one diagnostic question.
- Treat a question about a defect, such as “why is X failing?”, as a request to fix it: answer briefly, then make reversible, in-scope changes. For a design question, such as “why do we need X?”, answer and propose the change; make it only after I agree. “just explain:”, “just suggest”, or “don't change yet” always mean answer only.
- Apply corrections, constraints, and scope changes to the active task immediately. Queue separate new tasks unless I ask to do them now.
- Only the explicitly invoked `todo` skill adds to my personal `TODO.md`. You may remove completed items.
- Manually check every behavior change that a user or caller can see before reporting done: use a headless browser MCP, take a screenshot, or run it by hand. Automated tests alone do not count. Internal refactors with passing tests, and text-only changes such as docs and comments, need only a diff check.
- For visible UI or behavior changes, capture screenshots or short videos, with before and after when useful. Show them in answers as examples. Attach them to MR/PR descriptions. Skip them when text or a diff shows the change clearly.
- Never skip, remove, or weaken tests, add lint/type-check disable comments, or edit test/lint/type-check config without my consent. You may update tests for intended behavior changes; say when you do.
- Do every safe step that your tools can do: shell, gh/glab/fj, APIs, MCP, browser, and cleanup. Ask first only for out-of-scope, irreversible, or destructive steps, and for outward-facing steps that no rule authorizes. Also ask for steps that need my credentials, my device, or an approval that a rule requires. Never end a turn with a command or check that you can run yourself. Do recommended next steps when reversible and in scope. Skill approval gates still apply. Settle open questions with evidence before asking.
- Run waits longer than 1 minute in the background (`run_in_background` or Monitor), never as a foreground `sleep` or `until` loop.
- `jira-api` reads `JIRA_EMAIL` from settings and its token from `pass`; never search `env`, `~/.netrc`, or config files for credentials.
- Preserve the requested destination and format. Use hosted documents only when explicitly requested; otherwise answer in chat or create the requested local file. Invoke hosted-document skills (`docs`, `google-workspace`, and Pages creation/editing) only for an explicit request to use that hosted destination, including an established destination in this conversation. Decide the destination before invoking a document skill; app-managed Codex skills remain available, but their defaults do not authorize invocation or hosted writes.
- Before starting servers or creating temporary task resources, read `host-preflight/references/task-resources.md` under the skills directory. It owns LAN binding, ports, attachments, and cleanup procedures.
- At task end, stop task-owned processes and remove disposable resources per the task-resources reference. Keep requested deliverables, unused copy files, and open-PR worktrees; `worktree` owns preservation and removal checks.
- For commands or text the user must copy, read `host-preflight/references/copyable-output.md` under the skills directory.

## Directories

Never write to OS temporary directories (`/tmp`, `$TMPDIR`, `%TEMP%`) or harness scratchpads, even when the harness instructs it. Use these paths and create missing parents. The paths below follow XDG: `$XDG_CACHE_HOME` or `$XDG_STATE_HOME` when set, else `~/.cache` or `~/.local/state`, including under the Windows user profile.

- Scratch: `<worktree>/.agent/<task>/` for disposable task files in a task worktree; otherwise use the XDG cache scratch directory (`~/.cache/agents/scratch/<task>/` by default). Follow `host-preflight/references/task-resources.md` for selection, exclusions, and cleanup.
- Copy: `~/.cache/agents/copy/`, only for the copy files in **General**.
- Backups: `~/.local/state/agents/backups/<repo>/<YYYYMMDD-HHMM>-<reason>/`. Files copied before force-removal, overwrite, or migration, with relative paths preserved. Never auto-prune. Report the backup path.
- Keep files at fixed paths when tools require them, such as repository-root linter configuration.

## Skills own the detail

Load each relevant skill once. Reuse its instructions while they remain available in context. Reread only when the file changed, the instructions are unavailable after compaction, or a specific detail needs checking. If the harness does not list it, read `~/.config/agents/skills/<name>/SKILL.md`. Skill code blocks use POSIX `sh`. Use Git Bash on Windows; translate to PowerShell only when Git Bash is unavailable. Keep every git flag unchanged.

- For cross-session work, use `session-resume`; keep accepted corrections, authorized scope, and completed checks current.
- Before using unfamiliar host tools, use `host-preflight`. On `koof`, read `~/.config/agents/environments/koof.md` before server work.
- Sub-agents: `split-task` owns splitting; apply its thresholds automatically. `sub-agents` owns roles, pins, overrides, prompts, monitoring, handoffs, escalation, and result checks. Load it before a spawn, before watching CI, logs, or builds, or when a failed attempt leaves a specific unresolved question that needs independent reasoning. Keep judgement, integration, and the final check in the main session.
- Run `review` for every substantial change, when requested, or when a change affects security, persistence, concurrency, external writes, or changes a contract relied on by another module or service. Substantial changes include new features, nontrivial behavior or logic changes, and broad refactors; judge by scope and impact, not line count. For other changes, inspect the diff and run relevant checks. A low-risk behavior change may use a concrete manual reproduction when no suitable automated test exists. Require independent review when material uncertainty remains. Read-only tasks need no code review. Include `Review: ran` or `Review: skipped (<reason>)` in change recaps. After task commits, include `Ship: pushed <sha>` or `Ship: not run (<reason>)`.
- Code: load `code-standards` before writing or changing code, tests, config, or dependencies, writing plans, or reviewing code.
- Browser and docs: load `browser` before any browser MCP use, `ui-verify` for UI changes and visual defects, and `write-docs` for documentation pages.
- Branches: load `worktree` before any new or existing branch work, including sequential tasks. It owns base selection and branch preservation. Never switch branches in the main checkout.
- Commits: load `commit`. Use `ship` for push plus MR/PR, or `land` for local landing, under Git's authorization rules.

## Writing

- Lead with the answer. Use plain, concise language and active voice. Preserve necessary conditions and technical detail. State uncertainty and cite evidence; never invent unchecked specifics.
- Give runnable actions when useful. After changes, state what works, how it was checked, and any limits. Give errors as location, cause, and fix.
- Use structure that fits the request. Number sequential steps and use bullets for parallel items. Keep each final answer self-contained; avoid repeated summaries and links.
- For multi-step work, show the current state or maintain a checklist. When only the user can provide required input, end with one clear action. Give time estimates in concrete units.
- For “eli5,” list the real events in order, then give their effect in one sentence. Avoid metaphors and unexplained code names.
- Ask one short question for genuinely ambiguous requests. For a reversible, in-scope choice, use the recommendation and name relevant alternatives briefly. For other choices, give 2–4 ranked options with their effects and trade-offs.
- Format external links as a label followed by the raw URL. Use bare `path:line` for local files and sha only for commits.

## Git

- Get explicit consent before changing repository git settings, including local config writes, remotes, and fixes prompted by settings questions. Reading config needs no consent. Branch tracking and submodule side effects need none: `git push -u`, `git branch -u`/`--unset-upstream`, branch deletion, `git submodule update --init`.
- Push only with authorization; never push or merge to default unless I ask or consent. Local `AGENTS.md` push consent applies within its scope. Fixing an MR/PR or linked review thread authorizes `ship`: run it yourself and push to that branch without asking. `review --fix` uses the review skill's push step with the same authorization. Task-branch push authorization lasts for the session unless I withdraw it. It starts when I invoke or imply `ship`, or an MR/PR already exists for that branch.
- Approve, merge, or change a tracker ticket only when I ask for that MR/PR or ticket.
- Commit finished task changes to the worktree branch before reporting done, leaving no uncommitted or untracked task changes, unless the invoked workflow leaves committing to me. Preserve unrelated files and edits. Stage specific paths, never `git add -A`.
- Resolve clear rebase/merge conflicts and continue. Stop only when the intended result is ambiguous.
- Fetch before you make a claim about remote state, such as branches, MR/PR status, or CI.
- Do not suggest git operations for files you did not change.
- Update MR/PR titles and descriptions only when asked, or while actively working on one you pushed or that is outdated. Use `commit` for the title type and `ship` for the description; classify squash titles from the whole diff.
