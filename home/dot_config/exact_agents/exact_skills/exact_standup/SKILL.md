---
disable-model-invocation: true
name: standup
description: "Explicit-only: draft today's standup from Claude sessions, edit it in chat, then DM it in Slack."
---

Optional argument: `send` skips the review and DMs the standup right away.

1. **Send now.** With `send`, run `agent-standup` and report whether
   `~/.local/state/agents/standup/log` ends with `standup sent` or
   `standup skipped`. Stop.
2. **Draft.** Run `agent-standup --print`. Empty output means no Claude
   session or GitLab activity today; say so and stop.
3. **Show.** Print the draft verbatim in a `text` code block, so the user sees
   the exact Slack markup. Under it, add one line: the count of worktrees whose
   unpushed commits are older than 14 days (read-only):
   `find ~/Projects -maxdepth 7 -path '*/.worktrees/*' -name .git -exec sh -c 'for g; do w=${g%/.git}; t=$(git -C "$w" log HEAD --not --remotes --format=%ct 2>/dev/null | tail -1); [ -n "$t" ] && [ $(($(date +%s)-t)) -gt 1209600 ] && echo "$w"; done' sh {} + | wc -l`.
   Keep it out of the Slack text. Offer `worktree-cleanup` to review the list.
   Then ask for edits or `send`.
4. **Edit.** Apply each requested edit to the draft and show it again. Keep
   the `<url|label>` Slack link syntax and the Done, Next, Blocked sections.
5. **Send.** On `send`, DM the final text with `slack_send_message`, using the
   user's own Slack user ID from the Slack tool description as `channel_id`.
   Without a Slack tool, say so and leave the text in chat to paste. Report the
   message link.
