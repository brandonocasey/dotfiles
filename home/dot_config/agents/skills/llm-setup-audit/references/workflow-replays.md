# Replay historical workflow failures

After a workflow change, select applicable cases from
[workflow-cases.json](workflow-cases.json). These fixtures contain requests
and minimal state separately from expected outcomes. Add a case only for a
verified failure or a changed authorization boundary.

Run deterministic helper tests first. For skill decisions, run each case
in a fresh sub-agent per `sub-agents`, without conversation history. Give the
evaluator only the request, state, relevant skill, and permitted side effects.
Do not send the expected outcome, implementation rationale, or prior finding.
Use scratch fixtures and read-only tools. Do not push, merge, deploy, approve,
or send messages during a replay.

Compare the result with each expected condition after the evaluator returns.
Record case ID, skill revision, inputs, expected result, observed result, and
pass or fail. A narrated plan alone cannot prove helper behavior: run the
lookup, feedback wait, or other deterministic operation against its fixture.

Check task completion, retained choices, target branches, authorization,
and required user follow-ups. Repair demonstrated failures, then replay only
the affected cases. Do not claim token or time savings without comparable runs.
