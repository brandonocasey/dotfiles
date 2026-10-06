# Report a deployed preview

Preview URL: list one only when the platform reports it. Use the step 2
`HEAD_SHA`, not `HEAD` after cleanup. Never build one from CI files. Do not wait
for a deploy job.

- GitHub: `gh api "repos/{owner}/{repo}/deployments?sha=<HEAD_SHA>"`, then the
  `environment_url` from the deployment's `statuses_url`.
- GitLab: in `glab api "projects/:id/deployments?order_by=updated_at&sort=desc"`, find
  the newest deployment whose `sha` is `HEAD_SHA`. Use its `environment.external_url`.
  Without one, a deployment whose `ref` is `BRANCH` or `refs/merge-requests/<iid>/merge`
  can be listed only with the label `from <short sha>`, using its `sha`.
