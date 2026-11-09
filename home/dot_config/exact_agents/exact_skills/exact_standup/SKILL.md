---
disable-model-invocation: true
name: standup
description: "Explicit-only: draft today's standup from Claude sessions, edit it in chat, then DM it in Slack."
---

1. **Draft.** Run `agent-standup`. On empty output, read the last lines of `${XDG_STATE_HOME:-$HOME/.local/state}/agents/standup/log`. `standup skipped` means no Claude session or GitLab activity
   today; say so and stop. Otherwise report the logged error and stop.
   The draft cross-references Jira tickets through the attached MCPs and names the customer a fix is for when Slack or Jira show it. Drop any preamble line before the first italic project label.
2. **Show.** Print the draft verbatim in a `text` code block, so the user sees
   the exact Slack markup. Under the block, add one line: the count of linked worktrees
   whose oldest unpushed commit is older than 14 days (read-only):
   `find ~/Projects -maxdepth 6 \( -name node_modules -o -name .worktrees \) -prune -o -name .git -type d -print -prune | while read -r g; do git -C "${g%/.git}" worktree list --porcelain | sed -n 's/^worktree //p' | tail -n +2; done | while read -r w; do t=$(git -C "$w" log HEAD --not --remotes --format=%ct 2>/dev/null | tail -1); [ -n "$t" ] && [ $(($(date +%s)-t)) -gt 1209600 ] && echo "$w"; done | wc -l`.
   Keep it out of the Slack text. Say the user can run `worktree-cleanup` to review the list.
   Then ask for edits or `send`.
3. **Edit.** Apply each requested edit to the draft and show it again. Keep
   the `<url|label>` Slack link syntax, each bullet's `TYPE` badge, the `Next:`
   bullets, and the italic project labels. The draft has no sections; add none.
   Link only MRs, or one main ticket when the work has no MR; no pipelines, releases, commits, issues, or Slack threads. Keep customer names in the draft, which goes only to the user's DM, and never write customer names, ticket keys, or the Jira site URL into skills or dotfiles.
4. **Send.** On `send`, DM the final text with `slack_send_message`, using the
   user's own Slack user ID from the Slack tool description as `channel_id`.
   Without a Slack tool, say so and leave the text in chat to paste. Report the
   message link.
