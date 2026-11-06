# BambooHR days to calendar out-of-office

- Status (2026-11-06): current. `home/dot_config/time-off-sync/time-off-sync.gs` exists (one commit, unchanged since). It is a record copy; the live script runs in the user's Google Apps Script project, which was still on the old version when the session ended. Not a rule.
- Topic: Incidental doc use (the change was not driven by the source)
- Related: none in the plan (the Slack and time-off work is outside the agent-rule docs)

## Change
A Google Apps Script copy that mirrors BambooHR time off and US company holidays as out-of-office events on the primary Google Calendar, so Slack sets the status automatically. It runs hourly in Google's cloud, reads BambooHR's iCal "Who's Out" feed, and adds, moves or removes events to match. Sick days and Slack away/here are not covered: the user set those in Slack himself and asked to skip them.

## History
- 2026-10-15 — session 71a657ca: user asked to find an earlier session about marking himself out of office via the slackbots time-off page or its API, mostly to set away/here in Slack and parse Slack for messages. Then: "is there any way to sync bamboohr and google calendar automatically? then slack can use that and the sick message?". The assistant proposed an Apps Script (option 1) and a probe to confirm it could work. The user asked about a Slack workflow instead ("slack workflow doesn't seem to let me select a private channel?"), then said "alright skip sick and clean up any agent away stuff as needed".
- 2026-10-15 — review before commit: found 3 bugs and 2 questions, all fixed (see Results). The assistant said the fixes were not re-reviewed.
- 2026-10-15 — commit `4cf64d39 feat(time-off): sync BambooHR days to calendar out-of-office`: adds the script. Commit body: "Apps Script copy that mirrors BambooHR time off and US company holidays as out-of-office events, so Slack sets the status automatically." S named `55c2f931` (same subject and time), which is an orphan not reachable from main; `4cf64d39` is the reachable commit.
- 2026-11-06 — status check: file exists; `git log --follow` shows only this commit.

## Results
No measurement of the sync over time. What was probed:
- The probe (user ran it in Apps Script at 3:45 PM): "BambooHR reachable: HTTP 200", "Created out-of-office event ...", "Deleted it. Option 1 is viable." So Google's servers can read the BambooHR feed and create an out-of-office event.
- The assistant loaded the same feed from the public internet without VPN earlier: 101 entries, including the user's Oct 21-26 and Dec 4-7 vacations, each with a stable ID, so edits and cancellations can be tracked. Slackbots uses the same iCal feed, read every 6 hours, with no API key or login.
- Review findings fixed before commit: it read only the first page of calendar results (could keep re-adding events); it could delete finished time off the day after it ended if the calendar time zone differed from the script's; duplicate events were never cleaned up; the holiday filter would keep other countries' July "Independence Day" and similar; feed entries with no end date were dropped (now one day, per iCal). After the fixes, the reviewer's scenarios passed in three time zones; against the real feeds the script added exactly the two vacations, Thanksgiving and Christmas, and a second run changed nothing. Both runs used a simulated calendar.
- Final state: the user was told to paste the new copy over his Apps Script project and run `syncTimeOff` once; the log should show no "Added" or "Removed" lines. The result was not found in the session.
- Side finding recorded in the session: the slackbots time-off API returns the company feed link, with its secret ID, to anyone who calls it, and the link is committed in that repo. Unverified whether Google Workspace blocks Apps Script (stated as unverified before the probe passed).

## Sources
- [Google Calendar API, event types](https://developers.google.com/workspace/calendar/api/guides/event-types) — out-of-office event type. A calendar-status guide and a Slack help article on out-of-office were also read; their URLs were not preserved.

## Evidence
A probe showed Google's servers can read the BambooHR feed (HTTP 200) and create and delete an out-of-office event. Session 71a657ca (2026-10-15). The docs page was read by the assistant; fetch method not recorded.
