---
name: jira-versions
description: >
  Create, rename, release, archive, or list Jira fix versions (releases) for
  the PUBS project, and move tickets between them. Use when asked to create a
  release version or move a ticket to another version. The Atlassian MCP
  cannot create versions.
---

The Atlassian MCP and `acli` cannot manage versions. Use `jira-api`
(`~/.local/bin/jira-api`). It calls the Jira Cloud REST API v3 with curl.

## Setup

- Set `JIRA_EMAIL=bcasey@jwplayer.com` for each call. The shell does not set it.
- The token comes from `JIRA_API_TOKEN` or `pass show api/jira`.
- Check auth: `JIRA_EMAIL=bcasey@jwplayer.com jira-api GET /myself`
  (expect `HTTP 200`).

## Facts

- PUBS `projectId`: `15864`.
- Version names: `jwplayer-<x.y.z>` (example: `jwplayer-8.51.11`).
- Cloud ID for MCP calls: `f39bc534-3cc8-4984-954b-8d3b706c9ff4`.

## Commands

Every command is `JIRA_EMAIL=bcasey@jwplayer.com jira-api <METHOD> <path> [json]`.

- List versions: `GET /project/PUBS/versions`
- Read one: `GET /version/<id>`
- Create:
  `POST /version '{"name":"jwplayer-8.51.11","projectId":15864,"description":"Created <YYYY-MM-DD> at the request of <name>."}'`
- Rename or edit: `PUT /version/<id> '{"name":"...","description":"..."}'`
- Release: `PUT /version/<id> '{"released":true,"releaseDate":"<YYYY-MM-DD>"}'`
- Archive: `PUT /version/<id> '{"archived":true}'`
- Delete: `DELETE /version/<id>` (irreversible; get approval first).

Output ends with `HTTP <code>`. `201` means created, `200` means ok.

## Move a ticket to a version

1. Make sure the target version exists (`GET /project/PUBS/versions`).
   If not, create it first.
2. Use the Atlassian MCP `editJiraIssue` with
   `fields: {"fixVersions": [{"name": "jwplayer-8.51.11"}]}`.
   This replaces all fix versions on the ticket. Read the ticket first and
   keep versions that must stay (for example, already-released ones).
3. Read the ticket again to check the result.

## Rules

- Before moving a ticket, check which MR is merged. Merged work stays in the
  version it shipped in.
- Creating or editing a version is visible to the whole team. Release and
  delete need user approval.
