## Escalate with `consult`

Only the main session may escalate. Sub-agents report blockers without escalating.
Use the current model stated in the system prompt; do not invent one.
Request a fresh independent assessment when it can resolve a specific blocker,
even if the consultant uses the same model. Same-model consultation is exceptional: a
failed attempt must leave a concrete question that fresh reasoning can settle.

- **One hard sub-problem:** escalate when a failed attempt leaves a specific unresolved question that needs independent reasoning. Correct routine command, syntax, and setup errors inline.
  Spawn one `consult` with the problem, evidence, files, and points to settle.
  The task stays here, so no approval is needed. Re-validate the answer before acting.
  Escalate each sub-problem at most once.
- **Whole task on another model:** use a stronger model after failure or for subtle reasoning across systems.
  Use a cheaper role when the task permits it. Warn the user with the reason and get approval.
  Then give the full context to one `worker`, or `consult` when the current model is `worker`.
- Before reporting blocked, use `consult` when the unresolved question meets the
  escalation condition above and the role is available, including the same-model case. Missing credentials, permissions, or user decisions do not require a consultant.
