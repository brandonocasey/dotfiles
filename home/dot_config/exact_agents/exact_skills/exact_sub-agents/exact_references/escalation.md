## Failed attempts and loops

Loop caps (rounds, retests, fix checks) are ceilings. Stop a loop early when the same failure signature (check, error text, location) repeats or a round fixes nothing new.
After a failed attempt, retry in a fresh context with a 5-8 line brief of what was ruled out, with evidence paths. Classify the failure first:

- **Implementation** (the cause is believed right, the check fails): one fresh same-model retry given the check output. If it fails, treat it as a diagnosis failure; when it repeats the first failure's signature, the early stop applies: escalate once, then report blocked.
- **Diagnosis** (the cause is wrong, or there is no check): escalate to `consult` at once.

## Escalate with `consult`

Only the main session may escalate.
Use the current model stated in the system prompt; do not invent one.
Request a fresh independent assessment only when a failed attempt leaves a concrete question that fresh reasoning can settle, even if the consultant uses the same model.

- **One hard sub-problem:** correct routine command, syntax, and setup errors inline.
  Otherwise spawn one `consult` with the problem, evidence, files, and points to settle.
  The task stays here, so no approval is needed. Re-validate the answer before acting.
  Escalate each sub-problem at most once.
- **Whole task on another model:** use a stronger model after failure or for subtle reasoning across systems. Warn the user with the reason and get approval.
  Then give the full context to one `worker`, or `consult` when the current model is `worker`.
- Before reporting blocked, use `consult` when the question meets the condition above and the role is available. Missing credentials, permissions, or consent do not require a consultant.

## Settle open questions

Before asking the user an open question, the main session asks `consult` to pick. This covers every open question: ambiguity, design choices with no safe default, and choices where a wrong pick wastes substantial work. Reversible defaults the main session takes without asking need no pick.

- Batch every open question of the turn into one `consult` call.
- Keep the prompt short. Start it with `Pick:`, then per question: the question, the user's request wording when it bears on it, numbered options one line each, the constraints, and evidence as `path:line`, not pasted content.
- Re-validate each pick against the evidence before acting. Then act on it and list it in the final report as a decision for review. Ask the user only the undecided ones, with the consultant's reason.
- A pick never grants consent. Any action the global rules or a skill gate on consent (such as outward, destructive, credentials, device, spend, new dependencies, out-of-scope work, weakened tests, Git) still needs the user's approval. In answer-only turns ("just explain", design questions), a pick is a recommendation; change nothing.
- Never send these to `consult`; ask the user: a wrong premise in the user's request (global rules), and questions a skill holds for the user, such as review behavior-change `question` items (`review` fix.md and loop.md), and any other ask a rule or skill step mandates.
- When `consult` is unavailable, fails, or replies without one `Pick` or `Undecided` line per question, ask the user those questions.
