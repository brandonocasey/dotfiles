## Failed attempts and loops

Loop caps (rounds, retests, fix checks) are ceilings. Stop a loop early when the same failure signature (check, error text, location) repeats or a round fixes nothing new.
After a failed attempt, retry in a fresh context with a 5-8 line brief of what was ruled out, with evidence paths. Classify the failure first:

- **Implementation** (the cause is believed right, the check fails): one fresh same-model retry given the check output. If it fails, treat it as a diagnosis failure.
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
- Before reporting blocked, use `consult` when the question meets the condition above and the role is available. Missing credentials, permissions, or user decisions do not require a consultant.
