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
   session had a prompt today; say so and stop.
3. **Show.** Print the draft verbatim in a `text` code block, so the user sees
   the exact Slack markup. Then ask for edits or `send`.
4. **Edit.** Apply each requested edit to the draft and show it again. Keep
   the `<url|label>` Slack link syntax and the Done, Next, Blocked sections.
5. **Send.** On `send`, DM the final text with `slack_send_message`, using the
   user's own Slack user ID from the Slack tool description as `channel_id`.
   Without a Slack tool, say so and leave the text in chat to paste. Report the
   message link.
