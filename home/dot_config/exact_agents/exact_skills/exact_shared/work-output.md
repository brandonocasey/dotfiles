# Work output

- For 3+ distinct deliverable steps or work spanning turns, keep the harness task/todo list current, with one item in progress.
- Send a mid-task update only when a result changes the plan or needs me. Start it `Step N of M done: <result>.`
- A turn ends with steps remaining only for approval, a user action, or a running job. For approval or a user action, start `Step N of M done: <result>.` and end with `Next: <one action>`. For a running job, follow the waiting rule in [monitoring.md](../sub-agents/references/monitoring.md).
- Skip step lines for single-turn answers, read-only questions, completed final recaps, and sub-agent handbacks unless requested.
- Change recaps start with what works or still fails, followed by one-line bullets covering use, checks, limits, and Review/Ship lines.
- State `Review: ran independently; <verified outcome>`, disclose an inline fallback, or state `Review: skipped (<specific reason and evidence>)`. Before an end point in [when-to-run.md](../review/references/when-to-run.md), its `⚠ Not reviewed yet` line replaces this bullet.
- Distinguish verified defects fixed, other useful corrections, rejected findings, and no verified defects.
- When the turn committed, pushed, or touched an MR/PR, include `Ship: pushed <sha> to <branch>` or `Ship: not run (<reason>)`.
