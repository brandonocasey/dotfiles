## Broader mode

Use this mode only when the user's own message asks to rebase named pull
requests, or to get all their open pull requests green or merged. A request to
fix or watch stays in default mode. Process every selected pull request independently; one blocked
pull request must not stop the others. If the user narrows the request to
`report` or `status`, only inspect and report.

A pull request is passing when it is not a draft, is up to date with its base,
passes every required check, and has no unresolved conflict.

| Argument | Selection |
| --- | --- |
| none | `--author @me` |
| `auto-merge` | pull requests with `autoMergeRequest` set (GitLab: `merge_when_pipeline_succeeds`); author default still applies |
| `all` | drop the author default |
| `--author LOGIN`, `--assignee`, `--label`, `--base`, `--head`, `--search` | passed to `gh pr list` (GitLab: see [gitlab.md](gitlab.md)); `--author` replaces the default; filters combine with AND |
| `12 #34 !56 https://github.com/O/R/pull/56 https://gitlab.com/G/P/-/merge_requests/7 feature/x` | exactly these pull requests by number, URL, or head branch |
| `--repo OWNER/REPO` | another repository; URLs set their own repository |
| `merge` | also merge pull requests that reach the passing state without auto-merge |
| `approve` | also approve each listed passing pull request as the user; needs explicit numbers or URLs, refuse it with `all` or filters |
| `report`, `status` | read-only |

Run a fresh inventory at the start of every turn; do not rely on a list from a
previous turn.

```sh
git remote get-url origin
gh repo view --json nameWithOwner,defaultBranchRef,url
gh api user --jq .login
gh pr list --state open --limit 100 --author @me --json number,title,url,headRefName,headRefOid,baseRefName,author,isDraft,isCrossRepository,autoMergeRequest,mergeStateStatus,mergeable,reviewDecision
```

Replace `--author @me` with the parsed filters. If the list reaches its limit,
raise the limit until the inventory is complete. On any remote other than
GitHub or GitLab, stop before any mutation and name the unsupported platform.
If the selection is empty, report that and stop. Also record the base branch,
auto-merge method, and review decision.

Authorization in this mode adds to the default list: a rebase with a
lease-protected force-push on the user's own branch, and a manual merge under
[merge.md](merge.md) when `merge` is in the user's text. Do not wait for the user between authorized actions.

- Read the repository's `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and the CI
  documentation relevant to the failing check or changed paths. Apply the most
  specific rules.
- A branch is the user's own when the pull request author equals the login
  from `gh api user` and the head repository is the current repository. Only
  these branches may be rewritten. Never force-push another author's branch,
  and never force-push without `--force-with-lease=BRANCH:OBSERVED_SHA`.
- Approve only when the user's own text contains `approve`; never infer it.
- Do not request reviews, bypass required checks, or push to a fork-owned
  branch. Report those blockers with the exact owner and next action.
- Do not edit tests, lint configuration, or CI configuration only to make a
  check pass. Fix the cause, or report the check as blocked.

Diagnose with these read-only commands for each number `N`:

```sh
gh pr view N --json number,title,url,headRefName,headRefOid,baseRefName,author,isCrossRepository,headRepositoryOwner,isDraft,autoMergeRequest,mergeStateStatus,mergeable,reviewDecision,reviewRequests,reviews
gh pr view N --comments
gh pr checks N --required --json name,state,description,link,workflow,event
```

Classify the first real blocker, then check whether another needs attention.
Handle branch state before check state: a rebase restarts CI, so a fix pushed
to a stale branch wastes a run.

- `mergeStateStatus` is `BEHIND`, `mergeable` is `CONFLICTING`, or the
  repository requires linear history and the branch has merge commits: read
  [branch-repair.md](branch-repair.md). Finish stacked base PRs first.
- Required checks are pending: wait. Do not change code or rerun a running
  check. Read [watch.md](watch.md).
- A check failed: open the linked run and read the failure, not only its
  summary: `gh run view RUN_ID --log-failed`. Read
  [check-repair.md](check-repair.md). A second failure is a real failure.
- Review is required or changes were requested: report the missing reviewer or
  requested change. A review blocker does not stop check and branch work.
- The pull request is a draft: report that the author must mark it ready.
- The pull request is in a merge queue: report its queue state and wait.
- Permissions, policy, missing secrets, or an unknown merge state block it:
  report the exact API or check message and the owner who must act.

Do not call a pull request passing only because its visible checks are green.
Required checks, mergeability, draft state, and queue state control that.

Final report adds the author to each line, states what the skill is waiting on
(CI, a reviewer, an author, repository policy, or the user), and reports each
removed worktree and local branch or its exact retention blocker.
