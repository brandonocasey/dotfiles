---
disable-model-invocation: true
name: investigate
description: "User-invoked only: reproduce and fix reported bugs; isolate unresolved causes into actionable blockers."
---

Scope: Reproduce and fix a bug from an issue, error, log, URL, or description using available tools. Narrow unresolved causes to actionable blockers. User-invoked only.

# Investigate and fix an issue

The goal is a verified fix. When a fix is not possible, the goal is a narrowed
issue: the smallest reproduction, the suspect code, what is ruled out, and the
next check. Stop only at one of these two results or at a stop point named below.

Use every tool that can add evidence. When one tool fails or is not connected,
try the next one before you call a fact unknown.

Never comment on, edit, close, or transition issues, pull requests, or chat
threads unless the user asks. Never write to production data. Follow the Git
rules for commits and pushes.

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

If a tool for the source is not connected or fails to authenticate, tell the
user which one and continue with what is available.

List these facts. Mark each fact as missing or unverified:

- Environment: version or commit, OS, browser or runtime, device, configuration.
- Steps, input data, and URLs.
- Expected result, actual result, frequency, and first seen.
- The last version or commit that worked, if any.

Check the report's claims against code and data before you trust them. When a
claim is wrong, show the evidence; it changes the investigation.

## 2. Plan the reproduction

Use the smallest environment that shows the issue, in this order:

1. The reported environment, if you can reach it without side effects.
2. A deployed or released build of the reported version.
3. A local build. Load `worktree` before you check out another version or change
   code. Load the repository's run skill or README to start it.

Start each server on its own free port, bound to `0.0.0.0`. Report
`http://<lan-ip>:<port>`. Shell variables do not persist between tool calls,
so write the port number into each command.

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

On a live third-party page, never submit forms, sign in, buy, or click ads.
A click on an ad can bill the advertiser.

### Headed browser and sound

Headless is the default. Use a headed browser for the cases `browser` lists.

Audible sound is allowed when the issue is about audio: no sound, wrong
volume, mute state, unmuted autoplay, audio tracks, or audio sync. This is the
exception in the `browser` skill's sound rule. Rules:

- Before audible playback starts, tell the user in one line, for example
  "Starting headed Firefox with sound to check the audio track."
- Check the active harness's MCP configuration for a headed entry without `--mute-audio`.
  Use that entry; a page cannot undo a process-level mute.
- Unmute in the page and in the app, for example the media element's `muted`
  and `volume` and the app's own mute control.
- Browsers block unmuted autoplay without a user gesture. Use the MCP's click
  tool on the real control to make a gesture. Test both paths when autoplay is
  in scope.
- Stop playback and close the page as soon as the check is done.

Keep sound off for all other issues.

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
- Find what changed:
  ```sh
  git log --oneline <good>..<bad> -- <path>
  git log -S '<symbol>' --oneline
  git blame -L <start>,<end> <file>
  ```
- For a regression with a known good and bad version and no clear suspect, run
  `git bisect` in a worktree.
- Read the repository's architecture docs when the area is new to you.

State each hypothesis, then prove or disprove it with one check. Do not stack
guesses. After one failed hypothesis on a hard problem, follow `sub-agents` for
escalation.

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
7. Run `review`, then commit per `commit`. Push or open a pull request only
   when the Git rules allow it.

Before any irreversible step, such as a migration, a data fix, or a release,
show a read-only preview and get the user's approval.

If the fix fails, go back to section 4 with the new evidence. After one failed
fix, follow `sub-agents` for escalation. After three failed fixes, stop, name
the doubtful assumption, and ask one diagnostic question.

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

Then offer the next step, for example "Want me to push and open the pull
request?" or "Want me to post this on the issue?" Do neither without a yes,
unless the Git rules already allow the push.

## Cleanup

Before you hand back:

- Stop playback. Close every browser page and MCP session you opened.
- Stop servers and background processes you started, and make sure their ports
  are free: `lsof -nP -iTCP:<port> -sTCP:LISTEN`.
- Remove temporary logging, debug flags, scratch files, and test data. Keep
  screenshots only when they are in the report.
