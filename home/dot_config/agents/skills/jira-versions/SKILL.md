---
name: jira-versions
description: >
  Create, rename, release, archive, or list Jira fix versions (releases), and
  move tickets or MRs/PRs between them. Use when asked to create or release a
  version or move work to another version. The Atlassian MCP cannot create
  versions.
---

The Atlassian MCP and `acli` cannot manage versions. Use `jira-api`
(`~/.local/bin/jira-api`). It calls the Jira Cloud REST API v3 with curl.

## Setup

- Set `JIRA_EMAIL` to the user's Atlassian email for each call. The shell
  does not set it. Use `git config user.email` if no other source gives it.
- Set `JIRA_SITE` when the site is not the `jira-api` default.
- The token comes from `JIRA_API_TOKEN` or `pass show api/jira`.
- Check auth: `jira-api GET /myself` (expect `HTTP 200`). Its `accountId` is
  the current user.

## Project facts

Read the project key and the version-name format from the repository's
AGENTS.md, AGENTS_PROJECT.md, or skill config. Get `projectId` from
`GET /project/<KEY>` (`.id`).

Known: web-player uses `PUBS` (`projectId` `15864`) and `jwplayer-<x.y.z>`.

## Commands

Every command is `JIRA_EMAIL=<email> jira-api <METHOD> <path> [json]`.

- List versions: `GET /project/<KEY>/versions`
- Read one: `GET /version/<id>`
- Create:
  `POST /version '{"name":"<name>","projectId":<id>,"description":"Created <YYYY-MM-DD> at the request of <name>."}'`
- Rename or edit: `PUT /version/<id> '{"name":"...","description":"..."}'`
- Release:
  `PUT /version/<id> '{"released":true,"releaseDate":"<YYYY-MM-DD>","driver":"<accountId>"}'`
  (driver: the current user's `accountId`).
- Archive: `PUT /version/<id> '{"archived":true}'`
- Delete: `DELETE /version/<id>` (irreversible; get approval first).

Output ends with `HTTP <code>`. `201` means created, `200` means ok.

## Move a ticket or MR to a version

1. For an MR/PR number, find the ticket key in its title, branch, or
   description: `glab api "projects/:id/merge_requests/<iid>"` or
   `gh pr view <n> --json title,headRefName,body`.
2. Make sure the target version exists (`GET /project/<KEY>/versions`).
   If not, create it first.
3. Read the ticket's `fixVersions`. Remove only the unreleased source version.
   Add the target and keep all other versions.
4. Write the new list with the Atlassian MCP `editJiraIssue`
   (`fields: {"fixVersions": [{"name": "<name>"}, ...]}`). This field replaces
   the full list.
5. If the project labels MRs/PRs by release, change the label. Get the label
   format from the project's release skill or docs. GitLab:
   `glab api --method PUT "projects/:id/merge_requests/<iid>" -f "add_labels=<label>"`.
   GitHub: `gh pr edit <n> --add-label <label> --remove-label <old>`.
   Other platforms are unsupported: tell the user and skip this step.
6. Read the ticket again to check the result.

"Move" never removes a released version. "Out of the release" removes only
the named version.

## Rules

- Before moving a ticket, check which MR/PR is merged. Merged work stays in
  the version it shipped in.
- Creating or editing a version is visible to the whole team. Delete needs
  user approval. A user request to release a version is that approval.
