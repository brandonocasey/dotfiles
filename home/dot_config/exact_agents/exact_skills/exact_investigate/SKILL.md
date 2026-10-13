---
name: investigate
description: "Reproduce and fix reported bugs; isolate unresolved causes into actionable blockers."
---

The goal is a verified fix. When a fix is not possible, the goal is a narrowed
issue: the smallest reproduction, the suspect code, what is ruled out, and the
next check. Stop only at one of these two results or at a stop point named below.

Use every tool that can add evidence. When one tool fails or is not connected,
try the next one before you call a fact unknown.

Never comment on, edit, close, or transition issues, pull requests, or chat
threads unless the user asks. Never write to production data. Follow
[git-policy.md](../shared/git-policy.md) for commits and pushes.

## 0. Take stock of tools

Before you start, list what this session can use for this issue:

- MCP servers: connected tools and deferred tools found through the harness's tool search
  (issue trackers, error trackers, logs, chat, docs, browsers, databases).
- CLIs: check with `command -v <name>`, for example `gh`, `glab`, `curl`,
  `docker`, `kubectl`, and the language's debugger and profiler.
- Repository tools: package scripts, test suites, linters, debug builds, and
  run skills.
- Skills: `browser`, `real-safari`, `ui-verify`, `worktree`, `code-standards`,
  `review`, `commit`, and `sub-agents`.

Report a failed MCP connection or authentication to the user in one line, with
the command that fixes it, for example `! gh auth login`. Continue with the
other tools.

For independent checks, such as two browsers or two suspect versions, run them
in parallel sub-agents per `split-task` and `sub-agents`.

## 1. Read the report

Find the source from the input and read all of it: description, comments,
attachments, linked issues, and linked commits or merge requests.

| Input | How to read it |
| --- | --- |
| Issue tracker link (Jira, Linear, GitHub, GitLab, …) | The tracker's connected MCP. Else its CLI (`gh`, `glab`) or REST API. |
| Error tracker or monitoring link (Sentry, Datadog, …) | Its MCP or API: stack trace, first and last seen, release, tags, breadcrumbs. |
| Chat link (Slack, …) | Its MCP: the full thread, not only the linked message. |
| Web page URL | Step 3. Treat the page as read-only. |
| Error text, stack trace, or log | Search the code and history for the exact message. |
| Plain description | Ask one question only when reproduction is impossible without the answer. |

List these facts. Mark each fact as missing or unverified:

- Environment: version or commit, OS, browser or runtime, device, configuration.
- Steps, input data, and URLs.
- Expected result, actual result, frequency, and first seen.
- The last version or commit that worked, if any.

## 2. Plan the reproduction

Use the smallest environment that shows the issue, in this order:

1. The reported environment, if you can reach it without side effects.
2. A deployed or released build of the reported version.
3. A local build. Load `worktree` before you check out another version or change
   code. Load the repository's run skill or README to start it.

## 3. Reproduce and collect evidence

### Browser issues

Load `browser` before any browser MCP call. Pick the engine from the report. Use
`real-safari` for Safari-only issues or FairPlay DRM. Use `ui-verify` for layout
and interaction defects.

Open the console and network panels before the page loads, so early requests and
errors are recorded. Collect:

- Console errors and warnings, with stack traces.
- Network requests: status, headers, bodies, CORS, redirects, mixed content.
- The page's own debug switches and state, through `evaluate_script`.
- Screenshots at the failure point, and a performance trace for slowness.

Delegate browser-evidence gathering to an agent that returns only the needed
excerpt.

On a live third-party page, never submit forms, sign in, buy, or click ads.
A click on an ad can bill the advertiser.

### Headed browser and sound

Headless is the default. For audio issues (no sound, volume, mute, unmuted
autoplay, audio tracks, sync), follow `browser`
[audible-playback.md](../browser/references/audible-playback.md).

### CLI, service, and build issues

- Run the failing command yourself and capture exit code, stdout, and stderr.
- Turn on the tool's verbose or debug output (`--verbose`, `DEBUG=*`, log
  level settings). Name the flag you used in the report.
- Isolate the dependency: call the API or endpoint directly (`curl -sSi`), read
  the config the program actually loads, and compare versions (lockfile, `--version`).
- Read logs around the failure time. Correlate by request ID or timestamp.
- Run the narrowest existing test that covers the area. A new failing test is
  good evidence; keep it as the regression test for section 5.

Ask before you install a tool. Say which tool is missing and what it would show.

## 4. Find the cause in code

- Search for the exact error text, error code, and key symbols. Read each
  caller of the failing function.
- Find what changed with `git log`, `git log -S`, and `git blame`.
- For a regression with a known good and bad version and no clear suspect, run
  `git bisect` in a worktree.
- Read the repository's architecture docs when the area is new to you.

State each hypothesis, then prove or disprove it with one check. Do not stack
guesses.

## 5. Fix

Fix the cause, not the symptom. Fix it when the cause is in code or config that
this session can change. When the cause is outside, such as a third-party
service, a browser bug, or user data, add a safe workaround in reach if one
exists, and go to section 6 for the rest.

1. Load `worktree` and `code-standards`. Work in a worktree on a new branch.
2. Write a test that fails for the reported reason. Where no test harness fits,
   write the exact manual check instead.
3. Make the smallest change that makes the test pass. When two fixes are
   valid, take the one with the smaller blast radius and name the other.
4. Run the test, the related suites, the linter, and the type checker.
5. Repeat the original reproduction from section 3 against the fix, with the same
   tools. Capture before and after evidence, such as screenshots or logs.
6. Search for the same defect at sibling call sites, and fix them in the
   same change.
7. Commit per `commit`. Run `review` at the hand-off in
   `review/references/when-to-run.md` **Timing**. Push or open a pull request
   only when the Git rules allow it.

If a hypothesis or fix fails, go back to section 4 with the new evidence. After
one failure on a hard problem, follow `sub-agents` for escalation. After three
failed fixes, stop, name the doubtful assumption, and ask one diagnostic question.

## 6. Narrow down

When you cannot fix the issue, make it easy for the next person to fix:

- Reduce the reproduction to the fewest steps, inputs, and dependencies.
  Save a minimal repro (a test, a script, or a page) when it helps.
- Name the suspect code with `file:line`, or the first bad commit.
- List every hypothesis that is ruled out, with the check that ruled it out.
- Name the owner: the team, project, or upstream tracker.
- Draft the upstream issue or ticket text. Do not post it without a yes.
- Name the next check and the access or tool it needs.

## 7. Report

Start with the result: **Fixed** or **Narrowed**. Then give, in this order:

1. **Cause**: one or two sentences, with `file:line`.
2. **Evidence**: log and console lines, requests, screenshots, and the commit
   that introduced the issue.
3. **Repro**: numbered steps, environment, version, and input data.
4. **Scope**: who and what is affected, and what is not.
5. **Fix**: the branch, commit, and tests that prove it, with before and after
   evidence. For **Narrowed**: the ruled-out list, the owner, the draft
   upstream text, and the next check.

End with `Next:` naming the step that needs a yes, for example pushing and
opening the pull request, or posting on the issue.

## Cleanup

Clean up per
[task-resources.md](../host-preflight/references/task-resources.md). Also:

- Remove temporary logging, debug flags, and test data. Keep screenshots only
  when they are in the report.
- Remove bisect and repro worktrees you created. Keep the fix branch's.
