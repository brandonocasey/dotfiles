# HR days to calendar out-of-office

- Status (2026-11-06): current. `home/dot_config/time-off-sync/time-off-sync.gs` exists (one commit, unchanged since). It is a record copy; the live script runs in the user's calendar-script project, which was still on the old version when the session ended. Not a rule.
- Topic: Incidental doc use (the change was not driven by the source)
- Related: none in the plan (the chat and time-off work is outside the agent-rule docs)

## Change
A calendar script copy that mirrors HR-system time off and company holidays as out-of-office events on the primary calendar, so the chat app sets the status automatically. It runs hourly in the calendar vendor's cloud, reads the HR system's iCal time-off feed, and adds, moves or removes events to match. Sick days and chat away/here are not covered: the user set those in the chat app and asked to skip them.

## History
- 2026-10-15 — session 71a657ca: user asked to find an earlier session about marking out of office via an internal chat-bot time-off page or its API, mostly to set away/here in chat and parse chat for messages. Then: "is there any way to sync the HR system and the calendar automatically? then chat can use that and the sick message?". The assistant proposed a calendar script (option 1) and a probe to confirm it could work. The user asked about a chat workflow instead (it did not let them select a private channel), then said "alright skip sick and clean up any agent away stuff as needed".
- 2026-10-15 — review before commit: found 3 bugs and 2 questions, all fixed (see Results). The assistant said the fixes were not re-reviewed.
- 2026-10-15 — commit `4cf64d39 feat(time-off): sync HR days to calendar out-of-office` (vendor name removed from the subject here): adds the script. Commit body: a calendar script copy that mirrors HR time off and company holidays as out-of-office events, so chat sets the status automatically. The session named `55c2f931` (same subject and time), which is an orphan not reachable from main; `4cf64d39` is the reachable commit.
- 2026-11-06 — status check: file exists; `git log --follow` shows only this commit.

## Results
No measurement of the sync over time. What was probed:
- The probe (user ran it in the calendar script editor at 3:45 PM): "HR feed reachable: HTTP 200", "Created out-of-office event ...", "Deleted it. Option 1 is viable." So the calendar vendor's servers can read the HR feed and create an out-of-office event.
- The feed entries each have a stable ID, so edits and cancellations can be tracked.
- Review findings fixed before commit: it read only the first page of calendar results (could keep re-adding events); it could delete finished time off the day after it ended if the calendar time zone differed from the script's; duplicate events were never cleaned up; the holiday filter would keep other countries' July "Independence Day" and similar; feed entries with no end date were dropped (now one day, per iCal). After the fixes, the reviewer's scenarios passed in three time zones; against the real feeds the script added exactly the two time-off entries and two holidays, and a second run changed nothing. Both runs used a simulated calendar.
- Final state: the user was told to paste the new copy over the calendar-script project and run `syncTimeOff` once; the log should show no "Added" or "Removed" lines. The result was not found in the session.
- Unverified whether the calendar vendor's admin settings block such scripts (stated as unverified before the probe passed).

## Sources
- Calendar vendor API docs on event types (link removed) — out-of-office event type. A calendar-status guide and a chat help article on out-of-office were also read; their URLs were not preserved.

## Evidence
A probe showed the calendar vendor's servers can read the HR feed (HTTP 200) and create and delete an out-of-office event. Session 71a657ca (2026-10-15). The docs page was read by the assistant; fetch method not recorded.
