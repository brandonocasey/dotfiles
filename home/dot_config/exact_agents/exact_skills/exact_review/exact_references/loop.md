## 5. Optional: --loop [N]

`--loop` implies `--fix`. [when-to-run.md](when-to-run.md) **Follow-ups** adds it to
automatic reviews that need two reviewers; `--no-loop` turns that off. It runs up to two
cycles. Each cycle has one full review and up to N fix checks. N defaults to 3. A pass
is a full review or a fix check. A "major" finding is a `bug` of `high` or `medium`
severity, as defined in [output.md](output.md).

1. **Full review.** Start a fresh `reviewer` and `deep-review` pair per
   [delegation.md](delegation.md) on the whole current target. Re-verify, report, and
   fix as in steps 2–4. Hold behavior-change `question` items for the user.
2. **Fix check.** Run only when the previous pass applied a fix. Continue the same
   reviewers when the harness supports it (Claude Code: `SendMessage`); otherwise start
   fresh reviewers on the delta with surrounding context. Send each reviewer:
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
   and survives re-verification, or after N fix checks. Other findings are fixed or held
   but never start another fix check. A held `question` that a later pass re-raises is
   not new.
4. **Second cycle.** Repeat steps 1–3 once with a fresh pair that has no context from the
   first cycle. Skip it when the first full review found nothing that survived
   verification.
5. Stop. Do not start a third cycle. Report one numbered list of: held `question` items,
   major findings still open, other findings left unfixed, and fixes from the final
   cycle's last pass that no reviewer checked. When the list is not empty, ask the user
   how to proceed.

Kill a finding that an earlier pass killed, unless its code changed since that pass.
Rebuild and rerun the shared checks per [delegation.md](delegation.md) before each pass.
For an MR/PR, push after each pass per [remote-fixes.md](remote-fixes.md) items 1–6, but
keep auto-merge paused for the whole loop. When item 5 opens a replacement MR/PR, later
passes target it. Run once, after step 5: step 4's per-run report, `Ship:` line, and
worktree removal; the auto-merge restore; and step 7. Step 5's ask replaces step 4's
closing question. Run step 7 and the restore only when the list is empty or the user's
answer resolves or accepts every item; otherwise leave auto-merge off. Keep the
review worktree until then. If no sub-agent is available, stop after the first
full review and say that the next reviewer is not independent. Run the full manual pass
in each full review. In fix checks, rerun only manual cases whose behavior the fixes
under check changed.
