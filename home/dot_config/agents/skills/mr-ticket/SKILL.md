---
name: mr-ticket
description: "Find, create, link, and update tracker tickets for MR/PR work."
---

Scope: Find or create and link tracker tickets for MR/PRs; assign, transition, version, label, and update titles. Use for ticket requests.


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
- Jira: the Atlassian MCP. If it fails, use `jira-api` with `JIRA_EMAIL` set.
  Take the email from `git config user.email` or `atlassianUserInfo`; never
  hard-code it. Check auth with `jira-api GET /myself` first.
- Jira fix versions: use [jira-versions](../jira-versions/SKILL.md) when the
  project matches it. The Atlassian MCP cannot create versions.

## Steps (per MR/PR)

1. Read the MR/PR: title, description, branch, author, state, labels, and changed files.
2. Find keys with the regex in the branch, title, and description.
3. Pick the action:
   - The user said `none`: skip steps 4-9. Change nothing in the tracker or
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
5. Link related keys from step 2 with the tracker's "relates" link.
6. Move the status per the lifecycle. Never move a ticket backward.
7. Set the version when the user gave one or an MR/PR label names one.
   "Add to" keeps existing versions. "Move" removes only the unreleased source version.
   Keep all other versions, per `jira-versions`. Ask before moving a merged MR/PR's ticket.
8. When step 7 set a version, add the matching release label in the repo's
   format. For a move, remove only the source release label.
   Omit removal when that label is absent or equals the target label.
   Keep all other labels.
9. Append ` [<KEY>]` to the MR/PR title in the repo's format, only when it is absent.
   Keep other keys and the `<type>(<scope>):` prefix.
10. Read the ticket and MR/PR again to check each field.

## Report

One line per MR/PR: MR/PR URL, key (new or reused) with its ticket URL,
related links, status, version, label, title.

## Ticket writing

Use a summary under 10 words naming the outcome. Describe the problem,
expected result, acceptance check, and links in 1–10 bullets, as few as possible.
Apply the global Writing rules and repository templates. Reread before posting
and remove sentences repeating another sentence, the title, or the diff.
