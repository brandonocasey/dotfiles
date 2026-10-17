# Workflows

These rules keep a Workflow run's raw output out of the main session.

## Agents

- Workflow `agent()` calls skip `CLAUDE_CODE_SUBAGENT_MODEL` and inherit the session model. Pass the role as `agentType` and its Claude Code model from [roles.md](roles.md) as `model`, such as `claude-sonnet-5-5`.
- Check `cheap` and `explorer` first; without a fitting role, use `explorer` for read-only work and `worker` otherwise.
- Never omit `agentType`: the default agent loads every tool plus CLAUDE.md. Never use `consult` in a workflow.

## Setup

- Fetch diffs, MR/PR details, logs, and test output inside the workflow, as its first step, through `cheap` agents.
  They write raw output under the task's scratch directory and pass paths to later agents.
- The main session gathers only what it needs to design the workflow.
- To rerun or change a workflow, edit its script file and pass `scriptPath`; do not paste the script again.

## Results

- Agents return structured findings with paths and line numbers, not logs or file contents.
- Keep `log()` calls few and one line each; they reach the main session.
- The final result is a summary under about 2k tokens plus the scratch path of the full results.
  Read that file with `rg` or `sed -n`, only for parts you must verify.

## Progress

- Wait for the completion notice. Never read the journal, agent transcripts, or the task output file by hand while the run is live.
- For "status?", run `agent-wf-status <transcript-dir>` once and relay its lines. The launch output gives the transcript dir.
- For a run with 2 or more phases or an ETA over 10 minutes, start one Monitor on `agent-wf-status <transcript-dir> --follow`.
  Relay only failure and done lines, each as one sentence, plus phase lines the user asked for. Avoid idle wake-ups (scheduled checks, pings) during long runs. Set the Monitor timeout to the ETA plus 10 minutes, at most 1 hour; re-arm while the run is still going.
- When the user asks for updates every N minutes, add `--every <N>`. Keep that interval for the rest of the session.
- Follow mode exits only if the journal disappears. Stop its Monitor when the completion notice arrives.

## Between workflows

At each phase boundary of a multi-agent run, record a checkpoint with `agt task` or the ledger: phase, scratch dir, result paths, and verified status.
When a workflow with 10 or more agents finishes and the next step starts another workflow, also offer a fresh session that resumes from that record. Continue in this session if the user declines.
