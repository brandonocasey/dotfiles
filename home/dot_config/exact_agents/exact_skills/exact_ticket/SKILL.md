---
name: ticket
description: "Find, create, link, and update tracker tickets for MR/PR work; log pre-existing or found issues."
---

Arguments: `[<MR/PR url|number|branch>...] [to <version>] [none]`.
No MR/PR means the current branch's MR/PR.

The user's request is the approval for the ticket, MR/PR label, and title
writes. Do not ask per step. For several MRs/PRs, show the plan once and wait.
Push, merge, and approval keep their rules in
[git-policy.md](../shared/git-policy.md). Leave draft state alone unless asked.

## Read the conventions

Read them from the repository at run time: AGENTS.md, AGENTS_PROJECT.md,
CONTRIBUTING, README, and repo skill config files such as
`.claude/skills/*/config.md`. When those files name a shared config in another
checkout, read that file. Find these items:

- Tracker: Jira, or GitHub, GitLab, or Forgejo issues.
- Ticket-key regex and the project for new tickets.
- Status lifecycle: the status for an open and for a merged MR/PR.
- Version and release-label format.
- Rules that pick another project or no ticket, such as test-only changes.

Use only conventions that you found. When a needed item is missing, ask one
question. Never invent a key, project, status, or version.

## Tools

- Remote: `gh` for GitHub, `glab` for GitLab (`GITLAB_HOST` for self-hosted),
  `fj` or the Forgejo REST API for Forgejo. Other platforms: unsupported; stop
  before any write.
- GitHub and GitLab issues: `agt issue` (0.18.0 or newer) when `agt --version`
  works and a tracker for the repo is in `$XDG_CONFIG_HOME/agt/config.toml`
  (`~/.config` when unset). See [agt.md](../shared/agt.md).
  - Do not install `agt` here. Without it, or without a matching tracker, use
    `gh` or `glab`.
  - Reads use the local copy, synced first when it is stale (see
    [agt.md](../shared/agt.md)). Writes are queued and go out only on
    `agt issue push`, and only for trackers with `push = true`.
  - Do not change `push` in the agt config.
  - Run `agt issue sync --tracker <owner/repo>` before reads. On a sync error,
    stop, or read with `gh` or `glab`. An empty `find` after a failed sync does
    not mean "no ticket".
  - The sync scope `involved` can miss issues. Read a key that is not in the
    local copy with `gh` or `glab`.
- Jira: the Atlassian MCP. If it fails, use `jira-api` per the Setup in
  [jira-versions](../jira-versions/SKILL.md); `JIRA_EMAIL` comes from the
  environment, as that Setup says.
- Jira fix versions: use [jira-versions](../jira-versions/SKILL.md) when the
  project matches it. The Atlassian MCP cannot create versions.

## Steps (per MR/PR)

1. Read the MR/PR: title, description, branch, author, state, labels, and changed files.
2. Find keys with the regex in the branch, title, and description. For GitHub
   and GitLab tickets, also run `agt issue sync --tracker <owner/repo>`, then
   `agt issue list --pr <url>` for the linked issues. Use the MR/PR URL, or add
   `--tracker <owner/repo>` to a number: a bare number matches that PR in every
   synced tracker. Skip this when `agt` or a tracker is missing. Jira keys do
   not use `agt`.
3. Pick the action:
   - The user said `none`: skip steps 4-8. Change nothing in the tracker or
     the MR/PR. Report it.
   - A key for the target project exists: reuse it. Create nothing.
   - A repo rule selects another project or no ticket: follow it.
   - Otherwise: create a ticket.
4. Create the ticket:
   - Check the issue types first (Jira: `getJiraProjectIssueTypesMetadata`).
   - Pick the type from the commit type: `fix` is a bug; `feat` is a feature;
     other types are tasks. Use the names the tracker shows.
   - Summary and description: follow the repo's ticket rules, otherwise use
     **Ticket writing** below. Add the MR/PR URL.
   - Assign the MR/PR author. For Jira, use the `atlassian` account type.
     Find the accountId with `lookupJiraAccountId`: the author's commit email
     first, then the display name. On zero or several matches, leave the
     ticket unassigned and report it.
   - Never hand creation back to the user. Report a failed write with its error.
   - GitHub or GitLab ticket with a matching `agt` tracker: queue it with
     `agt issue create --tracker <owner/repo> --title <title> --body - --add-label <label>
     --add-assignee <login>`, reading the body from stdin. It prints a `local-` key.
   - Then run `agt issue link <key> --pr <url> --comment`.
   - Run `agt issue list --tracker <owner/repo> --pending`. Stop and ask when
     anything besides this run's keys is pending.
   - Run `agt issue push --tracker <owner/repo> --dry-run` and show it. Stop and
     ask when it touches other issues.
   - When `push = false`, the dry-run errors. Stop on that error and report the
     queued issue. Do not use `gh` or `glab` to bypass the setting.
   - Run `agt issue push --tracker <owner/repo>`. It sends every pending change
     on that tracker, so the pending check above is required.
   - Push exits 0 even with entries under `failed`, `deferred`, or `conflicts`.
     Treat any of them as a failed write and report it.
   - On success, the `local-` key becomes a number. Take `number` from the
     `sent` entry with kind create. Use `<owner/repo>#<number>` from then on.
     Never put a `local-` key in an MR/PR title.
   - With no tracker, create the ticket with `gh` or `glab`.
5. Link related keys from step 2 with the tracker's "relates" link.
   - On a GitHub or GitLab tracker, `agt issue link` is local only. It does not
     reach the host.
   - `agt issue link --pr <url> --comment` also queues a comment. Use it only for an MR/PR link.
   - For issue-to-issue links, name the related key in the ticket body or a
     comment. Queue it with `agt issue comment`, then push as in step 4.
   - Do not bypass `push = false` with `gh` or `glab`.
6. Move the status per the lifecycle. Never move a ticket backward.
   - For a GitHub or GitLab ticket with an `agt` tracker, close only when the
     lifecycle status is closed (the MR/PR is merged).
   - Queue it with `agt issue edit <key> --state closed` (add `--reason completed` on GitHub).
   - Then run the pending check, dry-run, and push as in step 4.
7. Set the version when the user gave one or an MR/PR label names one, and
   change the release label to match, per `jira-versions` (Move a ticket or MR).
   "Add to" keeps existing versions. Moving a merged MR/PR's ticket follows `jira-versions` Rules.
8. Append ` [<KEY>]` to the MR/PR title in the repo's format, only when it is absent.
   Keep other keys and the `<type>(<scope>):` prefix.
9. Read the ticket and MR/PR again to check each field.

## Report

One line per MR/PR: MR/PR URL, key (new or reused) with its ticket URL,
related links, status, version, label, title.

## Log found issues

When work turns up an issue outside its task, log it: a pre-existing
review finding, a check failure the change did not cause, or a new problem.

- Queue it locally with
  `agt issue create --tracker <owner/repo> --title <title> --body -`.
  Put its `local-` key in the `Separately:` line or the report.
- Push it only after the user agrees, per step 4: pending check, dry-run, push.
- When the user declines, drop it with `agt issue discard <key>` (agt 0.25.0 or newer).
  On an older agt, leave it queued and report its key.
- Without `agt` or a matching tracker, suggest `gh issue create` or
  `glab issue create` instead, as step 4 does.
- For a Jira project, suggest a Jira ticket per step 4 instead.
- Write the title and body per **Ticket writing**, with the evidence and `path:line`.

## Ticket writing

Use a short summary naming the outcome. Describe the problem, expected
result, acceptance check, and links in as few bullets as cover them.
Follow repository templates.
