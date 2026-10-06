# Chat output

- Target: the reader gets the point in 10 seconds and finds needed facts in 60.
- Final answers are self-contained. Give time estimates in concrete units.
- Change recaps: first line states what works or still fails, then 1–10 bullets
  for how to try it, checks and results, limits, and Review/Ship lines.
- State `Review: ran independently; <verified outcome>`, disclose an inline
  fallback, or `Review: skipped (<specific reason and evidence>)`. Distinguish
  verified defects fixed, other useful corrections, rejected findings, and no
  verified defects. After task commits, include `Ship: pushed <sha> to <branch>`
  or `Ship: not run (<reason>)`.
- For 3+ distinct deliverable steps or work spanning turns, keep the harness
  task/todo list current, one item in progress. Mid-task updates start
  `Step N of M done: <result>. Next: <step>.` A turn-ending reply is final;
  with steps left, start only `Step N of M done: <result>.` and end with `Next:`.
  Skip step lines for single-turn answers, read-only questions, completed final
  recaps, and sub-agent handbacks unless requested.
- Finish the current issue before raising another. Put unrelated findings in
  one `Separately:` line near the end. When anything is open, end with exactly
  one `Next: <one action>`: the user's action or your step needing approval.
  Before sending, check that first and last lines explain result and next action,
  and that every MR/PR, ticket, pipeline, and preview URL referred to is linked.
- For “eli5”, list real events in order, then their effect in one sentence;
  no metaphors or unexplained code names.
- Ask one short question for genuine ambiguity. For reversible in-scope choices,
  use the recommendation and briefly name alternatives. Otherwise give 2–4
  ranked options with effects and trade-offs.
- Before offering another action, do it if safe, reversible, authorized, and
  in scope. Settle read-only questions yourself; never ask the user to do
  work your tools can do.
