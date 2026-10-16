#!/usr/bin/env python3
"""SubagentStop hook: keep waiting subagents warm for 20 minutes, then hand off.

A subagent that stops while its own background shell job runs sits idle until
the job ends, and its 5-minute prompt cache expires. This hook makes it wake
every 4.5 minutes instead (one cheap cache read per wake), by requiring a
running `agent-wait` waiter. After 20 minutes of waiting it must write a
handoff file and stop with `HANDOFF: <path>`, so the main session can wait for
free and start a fresh agent from that file.

Exit 2 blocks the stop and shows the message to the subagent.
"""

import json
import os
import re
import sys
import time

STATE_ROOT = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
STATE = os.path.join(STATE_ROOT, "agents", "subagent-wait")
LOG = os.path.join(STATE_ROOT, "agents", "subagent-wait.log")
WARM_SECONDS = 20 * 60
WAITER = re.compile(r"\bagent-wait\b")
HANDOFF = re.compile(r"HANDOFF:\s*(\S+)")


def log(entry: dict) -> None:
    entry["at"] = time.strftime("%Y-%m-%dT%H:%M:%S")
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")


def own_running_shells(data: dict) -> list[dict]:
    """Running shell jobs this subagent started, found by id in its transcript."""
    running = [
        t
        for t in data.get("background_tasks") or []
        if t.get("type") == "shell" and t.get("status") == "running" and t.get("id")
    ]
    if not running:
        return []
    try:
        with open(data.get("agent_transcript_path") or "", encoding="utf-8") as f:
            transcript = f.read()
    except OSError:
        return []
    return [t for t in running if t["id"] in transcript]


def block(message: str, entry: dict) -> int:
    log({**entry, "decision": "block"})
    print(f"subagent-wait: {message}", file=sys.stderr)
    return 2


def main() -> int:
    data = json.load(sys.stdin)
    agent_id = data.get("agent_id") or ""
    if not agent_id:
        return 0
    os.makedirs(STATE, exist_ok=True)
    state_file = os.path.join(STATE, re.sub(r"[^A-Za-z0-9_-]", "_", agent_id))
    jobs = own_running_shells(data)
    entry = {"agent_id": agent_id, "agent_type": data.get("agent_type"),
             "jobs": [t.get("command") or t.get("description") for t in jobs]}

    if not jobs:
        if os.path.exists(state_file):
            os.remove(state_file)
        return 0

    message = data.get("last_assistant_message") or ""
    handoff = HANDOFF.search(message)
    if handoff and os.path.isfile(os.path.expanduser(handoff.group(1))):
        if os.path.exists(state_file):
            os.remove(state_file)
        log({**entry, "decision": "handoff", "file": handoff.group(1)})
        return 0

    now = time.time()
    try:
        with open(state_file, encoding="utf-8") as f:
            since = float(f.read().strip() or now)
    except (OSError, ValueError):
        since = now
        with open(state_file, "w", encoding="utf-8") as f:
            f.write(str(now))
    waited = now - since

    if waited >= WARM_SECONDS:
        scratch = data.get("scratchpad_dir") or "your scratch directory"
        target = os.path.join(scratch, f"handoff-{agent_id}.md")
        return block(
            f"You have waited {int(waited // 60)} minutes on background work. "
            f"Stop waiting: write a handoff file to {target} (a scratch note, "
            "allowed for read-only roles too; use a shell heredoc if you have no "
            "Write tool) with the task state, findings so far, the next step, "
            "each running job's log path, and the condition that means it is "
            "done. Stop your agent-wait waiter with TaskStop if you have it; "
            "otherwise leave it. Then end your reply with "
            f"`HANDOFF: {target}`.",
            {**entry, "waited": int(waited)},
        )

    if any(WAITER.search(t.get("command") or "") for t in jobs):
        log({**entry, "decision": "allow-waiter", "waited": int(waited)})
        return 0

    return block(
        "Your background job is still running, and an idle wait lets your "
        "prompt cache expire. Before stopping, start a waiter with "
        "run_in_background: true, e.g. `agent-wait --max 270 -- test -e <done-file>`. "
        "It wakes you within 4.5 minutes; check the job, re-arm the waiter if "
        "it still runs, then stop again. For jobs that may run past 20 "
        "minutes, start them detached instead of with run_in_background, so a "
        "handoff does not leave you parked until they end: "
        "`nohup setsid sh -c '<cmd> > <log> 2>&1; echo $? > <done-file>' "
        ">/dev/null 2>&1 &` returns at once.",
        {**entry, "waited": int(waited)},
    )


if __name__ == "__main__":
    sys.exit(main())
