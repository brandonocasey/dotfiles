---
disable-model-invocation: true
name: standup
description: "Explicit-only: draft today's standup from Claude sessions, edit it in chat, then DM it in Slack."
---

1. **Draft.** Run `agent-standup`. On empty output, read the log's
   last lines. `standup skipped` means no Claude session or GitLab activity
   today; say so and stop. Otherwise report the logged error and stop.
2. **Show.** Print the draft verbatim in a `text` code block, so the user sees
   the exact Slack markup. Each section groups its bullets under a bold
   project label. Under the block, add one line: the count of linked worktrees
   whose oldest unpushed commit is older than 14 days (read-only):
   `find ~/Projects -maxdepth 6 \( -name node_modules -o -name .worktrees \) -prune -o -name .git -type d -print -prune | while read -r g; do git -C "${g%/.git}" worktree list --porcelain | sed -n 's/^worktree //p' | tail -n +2; done | while read -r w; do t=$(git -C "$w" log HEAD --not --remotes --format=%ct 2>/dev/null | tail -1); [ -n "$t" ] && [ $(($(date +%s)-t)) -gt 1209600 ] && echo "$w"; done | wc -l`.
   Keep it out of the Slack text. Offer `worktree-cleanup` to review the list.
   Then ask for edits or `send`.
3. **Edit.** Apply each requested edit to the draft and show it again. Keep
   the `<url|label>` Slack link syntax, the Done, Next, Blocked sections, and
   the project labels.
4. **Send.** On `send`, DM the final text with `slack_send_message`, using the
   user's own Slack user ID from the Slack tool description as `channel_id`.
   Without a Slack tool, say so and leave the text in chat to paste. Report the
   message link.
