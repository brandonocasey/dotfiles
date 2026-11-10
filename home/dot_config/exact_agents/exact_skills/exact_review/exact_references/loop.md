## 5. Fix loop

Every review that fixes runs this loop: own work under [fix.md](fix.md) **Fix
authorization**, `--fix`, or a `fix` reply. It runs up to two cycles. Each cycle has
one full review and up to 3 fix checks. A pass is a full review or a fix check. A
"major" finding is a `bug` of `high` or `medium` severity, as defined in
[output.md](output.md), that the change introduced or made reachable; a
`pre-existing` finding is never major.

1. **Full review.** Run the testing stage in [testing.md](testing.md) first: the whole
   target in the first cycle, a retest of the changed code in the second. Then start
   fresh reviewers per steps 0–2 of [SKILL.md](../SKILL.md) on the whole current target. Re-verify, report, and fix as in steps 2–4. Hold
   behavior-change `question` items for the user.
2. **Fix check.** Run only when the previous pass fixed a major finding. The fixes were
   retested before their commit ([fix.md](fix.md) step 4). Continue the same
   reviewers when the harness supports it (Claude Code: `SendMessage`) and their last
   turn ended under 5 minutes ago; otherwise start fresh reviewers on the delta with
   surrounding context, since continuing after the cache expires rewrites their whole
   context. After one failed continuation, start fresh reviewers for that cycle's
   remaining fix checks. Start fresh fix-check reviewers with `model: sonnet` (effort
   stays `xhigh`); `--agents` overrides this. Send each reviewer:
   - the output of `agt review list --run <run> --cycle <n> --format prompt`
     ([store.md](store.md)): every surviving finding from this cycle, from any reviewer,
     with its applied fix, and each killed finding with its one-line reason;
   - the fix delta. The delta is
     `<last-reviewed-sha>..<new-head-sha>`; for a working-diff target, save the new
     working diff to a file and send both the old and new diff paths.

   Ask them to mark each surviving finding `fixed` or `not fixed` with evidence, then
   review the delta and the code it calls or is called by, returning new findings in the
   usual format. Re-verify and fix as in step 1.
3. Repeat step 2 until a fix check finds no major finding that is new or `not fixed`
   and survives re-verification, after 3 fix checks, or sooner per
   [escalation.md](../../sub-agents/references/escalation.md). Other findings are fixed or held
   but never start another fix check. A held `question` or a `pre-existing` finding
   that a later pass re-raises is not new.
4. **Second cycle.** Repeat steps 1–3 once with fresh reviewers that have no context
   from the first cycle. Skip it when the first full review found no `high` severity
   major finding that survived verification. Its full review runs blind: send the
   reviewers nothing from cycle 1.
5. Stop. Do not start a third cycle. After the last pass, run the **Writing pass** below
   once. Report one numbered list of: held `question` items,
   major findings still open, other findings left unfixed, and fixes of major findings
   from the final cycle's last pass that no reviewer checked. When the list is not empty, ask the user
   how to proceed. When the second cycle's full review still found a major finding,
   name the recurring cause in one line and suggest rethinking the approach before
   more fixes.

**Writing pass.** The fix loop's reviewers skip writing; only the first cycle's full review
runs the `writing-reviewer`. When the loop's fixes changed docs, code comments, or the MR/PR
title or description, and the first writing review ran, start one fresh `writing-reviewer`
with setup.md's writing prompt on the fix delta, `<head-sha at the first writing
review>..<final head>`; for a working-diff target, save the new working diff to a file and
send the old and new diff paths. Add `Commits: skip` to its prompt: fix commits cannot
be reworded. Record no store pass for it: any pass counts as a code
review in `reviews_at_head`. Fix its findings per [fix.md](fix.md) without store resolves,
and start no further pass; list any it leaves unfixed in step 5's list. The
cap is one writing pass per run. Fix checks never continue or start the `writing-reviewer`.

Keep the loop state in the store per [store.md](store.md): `pass start --kind full
--base <pinned base>` with each
reviewer, plus `fix` for fixes; one `pass end --findings -` with the pass's verified and killed findings;
`resolve <ids> --fixed <sha>` for the fixes; `resolve <id> --not-fixed <reason>` as the
fix-check reviewer; `resolve --triage question` for held items, and `reply --local`
with the user's answer when it comes. For a commit or range target, pass `--head HEAD`
per [store.md](store.md).

Kill a finding that an earlier pass killed, unless its code changed since that pass.
Before each pass, rerun setup per step 0–2 of [SKILL.md](../SKILL.md), passing the review worktree.
For an MR/PR, push after each pass per [fix.md](fix.md) MR/PR items 1–6, but
keep auto-merge paused for the whole loop. When item 5 opens a replacement MR/PR, later
passes target it. On an own MR/PR, after each pass and its push, run `agt review
publish` per **Own MR/PR comments** in [remote-comments.md](remote-comments.md). Run
once, after step 5's last pass and its fix commits, in this order: `run end` (in the
same call as any scratch cleanup that needs no worktree), a last
`publish` with the final summary (own MR/PR only), the auto-merge restore,
step 7, then step 4's per-run report, `Ship:` line, and worktree removal. Step 5's ask replaces step 4's
closing question. Run step 7 and the restore only when the list is empty or the user's
answer resolves or accepts every item; otherwise leave auto-merge off. Keep the
review worktree until then. If no sub-agent is available, stop after the first
full review and say that the next reviewer is not independent. Test results go to
the QA store ([testing.md](testing.md) **Record**), never to the review store.
