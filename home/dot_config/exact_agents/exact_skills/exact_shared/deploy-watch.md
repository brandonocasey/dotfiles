# Watch deploys

Applies after every merge into a branch whose pipeline deploys or releases, and
after every deploy or release you start (a manual job, a release pipeline, a
deploy script, a workflow dispatch), in any skill or none. Watching is read-only:
start it without asking. Skip it only when the user says not to watch, and say so
in the report.

## Find the deploy

Use the merge commit, or the commit the deploy runs on, as `SHA`.

- GitLab: `glab api "projects/:id/pipelines?sha=<SHA>"` lists its pipelines,
  including tag pipelines a release creates. List each one's jobs with
  `glab api "projects/:id/pipelines/<id>/jobs?per_page=100"`; jobs in a `deploy`
  or `release` stage, or named for deploy, release, publish, promote, or purge,
  are the deploy.
- GitHub: `gh run list --commit <SHA>`; runs whose jobs deploy, release, or
  publish, or that use an environment, are the deploy.

When no pipeline for `SHA` deploys, say `Deploy: none for <SHA>` and stop. When
the pipeline has not started yet, look again once after CI for the merge starts.

## Watch

Run each watch as a background command and wait for its exit, per the waiting
rules in AGENTS.md:

- GitLab: `agt ci wait <pipeline URL> --timeout 3300`, one target per deploy
  pipeline. A pipeline left waiting on a manual job exits 1; report that job as
  waiting for a person, not as a failure.
- GitHub: `gh run watch <run-id> --exit-status`.
- Other platforms: report `Deploy: not watched (<platform>)`.

On exit, report one line per pipeline: deployed, failed with each failed job's
URL and first error, waiting on a manual job, or still running at the timeout.
A failed deploy is reported, not retried or repaired, unless the user asks.
