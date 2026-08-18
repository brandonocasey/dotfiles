---
disable-model-invocation: true
name: tandem
description: >
  Run a set of user-given tasks in parallel: split them across sub-agents (one
  worktree per task), adversarially review each result via the review skill, fix
  verified findings, and report when everything the user asked for is done. Takes
  any number of explicit tasks or endpoints, or a list source (TODO.md, a ticket
  list, a file) with instructions to pick the tasks that can run in tandem. Use
  when the user says "do these in parallel", "run these tasks in tandem", "work
  through this list", "pick what can run together and do it", or invokes /tandem.
  End modes: /tandem ship (or "tandem-ship") pushes each finished branch as an MR
  via the ship skill; /tandem land (or "tandem-land") merges each branch locally
  via the land skill; default is neither — branches stay local.
---

Take a batch of tasks, run them in parallel sub-agents, adversarially review every
result, and report when the batch is done. Spawn mechanics follow the `sub-agents`
skill; review follows the `review` skill; commits follow the `commit` skill.

## Modes and arguments

- **End mode** — from the invocation: `ship` / "tandem-ship" (after review, run
  the `ship` skill per branch: push, open MR, babysit CI), `land` / "tandem-land"
  (run the `land` skill per branch: local merge to default, cleanup). Default:
  neither — branches stay local and committed.
- **User-defined splits** — if the user says how to split the work ("3 agents",
  "one agent per package", "group tasks 1+3, run 2 alone", a model per group),
  their split overrides step 2's automatic grouping. Warn once with a concrete
  reason if a user split makes two parallel agents share files, then follow their
  call.
- **User-defined agents** — if the user names what runs a task or group (a custom
  agent type from the harness's roster, a specific model, or an external tool),
  use exactly that; it overrides the `sub-agents` skill's tier choice for that
  assignment. Unknown agent names are a blocker: ask before spawning.

## 1. Collect the tasks

Two input modes:

- **Explicit** — the user lists the tasks (or endpoints/outcomes) directly. Take
  them verbatim.
- **Pick from a list** — the user points at a source (TODO.md, a Jira filter, a
  file, an earlier message) and asks you to pick tasks that can run in tandem.
  Read the source, then pick tasks that are: independent of each other, unlikely
  to touch the same files, and completable without user decisions mid-flight.
  Skip tasks that are destructive, outward-facing, or too vague to have
  acceptance criteria — list the skipped ones and why in the final report.
  Never add items to `TODO.md` or any other list source; removing items the
  batch completed is fine. Report completions either way.

For every selected task, write one line of acceptance criteria: what must be true
for it to count as done. If a task has no checkable outcome, ask the user before
spawning anything — this and an unknown agent name (see Modes) are the only
up-front questions.

State the selected set and the plan in one short message, then proceed.

## 2. Split and spawn

- Use the user's split when they gave one (see Modes). Otherwise group tasks
  whose expected file footprints overlap into the same agent (run sequentially
  inside it); everything else gets its own agent.
- Code tasks: one worktree per agent, created per the `worktree` skill — it owns the
  commands and the base-branch rule. This skill's only delta is the naming: path
  `.worktrees/tandem-<slug>`, branch `<type>/<slug>`. Non-code tasks (research, docs
  lookups, external checks) run without a worktree.
- Each prompt is self-contained per the `sub-agents` skill and must include: the
  task, its acceptance criteria, the worktree path (and its own `PORT` if it runs
  a server), the hard boundary (edit only inside your worktree), and the return
  contract — a raw status report: done / blocked / partial, what changed, how it
  was verified, files touched.
- Spawn each group with its assigned agent type/model when the user set one (see
  Modes); otherwise pick per the `sub-agents` skill.
- Run the agents in parallel. While waiting, do not idle-poll; act on completion
  notifications.

## 3. Adversarial review

For every returned task, in the main session:

- Check the result against its acceptance criteria first. A "done" claim with no
  evidence is treated as unverified.
- Code tasks: run the `review` skill on the task's diff in its worktree. This is
  the session's own work, so fix verified findings without asking, then re-run
  the project's tests and lint in that worktree (fixes are yours; never
  "pre-existing"). Do not re-review after fixes.
- Non-code tasks: spawn one verifier agent prompted to **refute** the result
  against the acceptance criteria; uncertain means refuted. Refuted results go
  back for one redo (per the `sub-agents` skill, at most one respawn per part —
  after that, fix inline or mark the task blocked).

## 4. Close out

- Commit each worktree via the `commit` skill so nothing is left uncommitted.
- Apply the end mode: `ship` — run the `ship` skill per branch (skip blocked
  tasks' branches); `land` — run the `land` skill per branch, one at a time.
  No end mode: leave branches local.
- Clean up everything the batch opened: stop servers, free ports, close browser
  pages. Keep worktrees with commits; remove empty ones.
- Report, self-contained: per task — done / blocked / skipped, one plain
  sentence, its verification evidence, and its branch + worktree path for code
  tasks. Include what was picked vs skipped in pick-from-list mode. End with a
  **Links** section for external links only (tickets, MRs, CI), and one concrete
  next action (with no end mode, usually "say `ship <branch>` to open MRs"; with
  `ship`, the MR links; with `land`, the landed default-branch state).

## Hard rules

- Nothing is reported "done" without passing review (or refutation) against its
  acceptance criteria.
- Agents write only inside their own worktree; disjoint ownership between
  parallel agents.
- Never merge, push, or touch tickets/MRs unless the user asks.
