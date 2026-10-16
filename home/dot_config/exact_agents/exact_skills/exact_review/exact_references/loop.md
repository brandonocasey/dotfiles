## 5. Fix loop

Every review that fixes runs this loop: own work under [fix.md](fix.md) **Fix
authorization**, `--fix`, or a `fix` reply. It runs up to two cycles. Each cycle has
one full review and up to 3 fix checks. A pass is a full review or a fix check. A
"major" finding is a `bug` of `high` or `medium` severity, as defined in
[output.md](output.md).

1. **Full review.** Start fresh reviewers per steps 0–2 of [SKILL.md](../SKILL.md) on the
   whole current target. Re-verify, report, and fix as in steps 2–4. Hold
   behavior-change `question` items for the user.
2. **Fix check.** Run only when the previous pass fixed a major finding. Continue the same
   reviewers when the harness supports it (Claude Code: `SendMessage`) and their last
   turn ended under 5 minutes ago; otherwise start fresh reviewers on the delta with
   surrounding context, since continuing after the cache expires rewrites their whole
   context. Send each reviewer:
   - every surviving finding from this cycle, from any reviewer or the manual pass, with
     its applied fix;
   - each killed finding with its one-line reason;
   - the fix delta and the new check logs. The delta is
     `<last-reviewed-sha>..<new-head-sha>`; for a working-diff target, save the new
     working diff to a file and send both the old and new diff paths.

   Ask them to mark each surviving finding `fixed` or `not fixed` with evidence, then
   review the delta and the code it calls or is called by, returning new findings in the
   usual format. Re-verify and fix as in step 1.
3. Repeat step 2 until a fix check finds no major finding that is new or `not fixed`
   and survives re-verification, or after 3 fix checks. Other findings are fixed or held
   but never start another fix check. A held `question` that a later pass re-raises is
   not new.
4. **Second cycle.** Repeat steps 1–3 once with fresh reviewers that have no context
   from the first cycle. Skip it when the first full review found no major finding that
   survived verification. Its full review runs blind, then reveals:
   - **Lock.** When the reviewers return, save their findings unchanged to
     `blind-<run>.md` in the task scratch directory. Never change them after the reveal.
   - **Reveal.** Continue each reviewer (Claude Code: `SendMessage`) with every cycle 1
     finding: its comment link, fix commit, and fix-check result, plus held `question`
     items with any answers. Ask it to mark each fix or answer `agree` or `disagree`
     with evidence, and to return new findings in the usual format, tagged
     `post-reveal`. Without continuation support, skip the reveal and say so.
   - Re-verify the blind and reveal findings together. A surviving `disagree` reopens
     its cycle 1 finding as `not fixed`.
5. Stop. Do not start a third cycle. Report one numbered list of: held `question` items,
   major findings still open, other findings left unfixed, and fixes of major findings
   from the final cycle's last pass that no reviewer checked. When the list is not empty, ask the user
   how to proceed.

After each pass, record the loop state (run ID, cycle, pass number, last-reviewed SHA, held `question` items, and per reviewer: its ID, model, effort, harness, harness version, starting context, and posted comment IDs) in the phase checkpoint per [workflows.md](../../sub-agents/references/workflows.md).

Kill a finding that an earlier pass killed, unless its code changed since that pass.
Before each pass, rerun setup per step 0–2 of [SKILL.md](../SKILL.md), passing the review worktree.
For an MR/PR, push after each pass per [fix.md](fix.md) MR/PR items 1–6, but
keep auto-merge paused for the whole loop. When item 5 opens a replacement MR/PR, later
passes target it. On an own MR/PR, after each pass and its push, start one posting
agent per **Own MR/PR comments** in [remote-comments.md](remote-comments.md). Run once,
after step 5, in this order: the last pass's posting agent with the final record
(own MR/PR only), the auto-merge restore,
step 7, then step 4's per-run report, `Ship:` line, and worktree removal. Step 5's ask replaces step 4's
closing question. Run step 7 and the restore only when the list is empty or the user's
answer resolves or accepts every item; otherwise leave auto-merge off. Keep the
review worktree until then. If no sub-agent is available, stop after the first
full review and say that the next reviewer is not independent. Run the full manual pass
in each full review. In fix checks, rerun only manual cases whose behavior the fixes
under check changed.
