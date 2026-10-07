# Work output

- For 3+ distinct deliverable steps or work spanning turns, keep the harness task/todo list current, with one item in progress.
- Mid-task updates start: `Step N of M done: <result>. Next: <step>.`
- A turn-ending reply is final. With steps remaining, start: `Step N of M done: <result>.` End with `Next: <one action>`.
- Skip step lines for single-turn answers, read-only questions, completed final recaps, and sub-agent handbacks unless requested.
- Change recaps start with what works or still fails, followed by ≤5 one-line bullets covering use, checks, limits, and Review/Ship lines.
- State `Review: ran independently; <verified outcome>`, disclose an inline fallback, or state `Review: skipped (<specific reason and evidence>)`.
- Distinguish verified defects fixed, other useful corrections, rejected findings, and no verified defects.
- When the turn committed, pushed, or touched an MR/PR, include `Ship: pushed <sha> to <branch>` or `Ship: not run (<reason>)`.
