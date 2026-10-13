---
name: jenkins
description: "Inspect Jenkins jobs, builds, and logs, or trigger requested builds via jenkins-api."
---

Use `jenkins-api` (`~/.local/bin/jenkins-api`). It calls the Jenkins REST API
with curl.

## Setup

- The login is `JENKINS_USER`, else `$USER`.
- The token comes from `JENKINS_TOKEN` or `pass show api/jenkins`.
- The server URL comes from `JENKINS_URL` or `pass show api/jenkins-url`.
  The server needs VPN.
- Check auth: `jenkins-api GET /me/api/json` (expect `HTTP 200`).

## Commands

Every command is `jenkins-api <METHOD> <path> [form-body]`.
Folders nest as `/job/<folder>/job/<name>`. URL-encode job names
(spaces as `%20`).

- List jobs: `GET /api/json?tree=jobs[name,url,color]`
- Job builds: `GET /job/<name>/api/json?tree=builds[number,result,url]{0,10}`
- Build result: `GET /job/<name>/<number>/api/json?tree=result,building,duration`
- Console log `GET /job/<name>/<number>/consoleText`; start `POST /job/<name>/build` (or `buildWithParameters 'KEY=value&K2=v2'`); stop `POST /job/<name>/<number>/stop`

Output ends with `HTTP <code>`. `201` means queued, `200` means ok.

Releasing a hive package: read [release.md](references/release.md).

## Rules

- Read calls need no approval.
- Starting or stopping a build uses shared CI. Get user approval first,
  unless the user asked for that build.
