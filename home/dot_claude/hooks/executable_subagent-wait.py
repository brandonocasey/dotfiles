#!/usr/bin/env python3
"""SubagentStop hook: keep waiting subagents warm for 20 minutes, then hand off.

A subagent that stops while its own background shell job runs sits idle until
the job ends, and its 5-minute prompt cache expires. This hook makes it wake
every 4.5 minutes instead (one cheap cache read per wake), by requiring a
running `agent-wait` waiter. After 20 minutes of waiting on the same jobs it
must write a handoff file and hand back with `HANDOFF: <path>`, so the main
session can wait for free and start a fresh agent from that file.

Only SubagentHandback messages reach the main session; plain reply text does
not. A handback ends the turn, so this hook often runs right after one.

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
HANDOFF = re.compile(r"HANDOFF:[*_`\s]*([^\s`*]+)")
REPORT = (
    "Report only through SubagentHandback; plain reply text never reaches "
    "the main session."
)


def log(entry: dict) -> None:
    entry["at"] = time.strftime("%Y-%m-%dT%H:%M:%S")
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")


def read_transcript(data: dict) -> str:
    try:
        with open(data.get("agent_transcript_path") or "", encoding="utf-8") as f:
            return f.read()
    except OSError:
        return ""


def own_running_shells(data: dict, transcript: str) -> list[dict]:
    """Running shell jobs this subagent started, found by id in its transcript."""
    return [
        t
        for t in data.get("background_tasks") or []
        if t.get("type") == "shell" and t.get("status") == "running"
        and t.get("id") and t["id"] in transcript
    ]


def last_handback(transcript: str) -> str:
    """Message of the latest SubagentHandback call, or ""."""
    for line in reversed(transcript.splitlines()):
        if '"SubagentHandback"' not in line:
            continue
        try:
            content = json.loads(line).get("message", {}).get("content") or []
        except (ValueError, AttributeError):
            continue
        for part in content if isinstance(content, list) else []:
            if part.get("type") == "tool_use" and part.get("name") == "SubagentHandback":
                return str((part.get("input") or {}).get("message") or "")
    return ""


def handoff_file(text: str) -> str:
    m = HANDOFF.search(text)
    path = os.path.expanduser(m.group(1).rstrip(".,;:)]'\"")) if m else ""
    return path if path and os.path.isfile(path) else ""


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
    transcript = read_transcript(data)
    jobs = own_running_shells(data, transcript)
    entry = {"agent_id": agent_id, "agent_type": data.get("agent_type"),
             "jobs": [t.get("command") or t.get("description") for t in jobs]}

    if not jobs:
        if os.path.exists(state_file):
            os.remove(state_file)
        return 0

    handoff = handoff_file(last_handback(transcript)) or handoff_file(
        data.get("last_assistant_message") or ""
    )
    if handoff:
        if os.path.exists(state_file):
            os.remove(state_file)
        log({**entry, "decision": "handoff", "file": handoff})
        return 0

    # The clock covers waits on the same work jobs. A new job (work done
    # between jobs) starts a new wait.
    now = time.time()
    work = sorted(t["id"] for t in jobs if not WAITER.search(t.get("command") or ""))
    try:
        with open(state_file, encoding="utf-8") as f:
            state = json.load(f)
        since, known = float(state["since"]), state["jobs"]
    except (OSError, ValueError, KeyError, TypeError):
        since, known = now, []
    if not set(work) <= set(known):
        since = now
    with open(state_file, "w", encoding="utf-8") as f:
        json.dump({"since": since, "jobs": work}, f)
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
            "otherwise leave it. Then call SubagentHandback with a message "
            f"that ends with the line HANDOFF: {target}. {REPORT}",
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
        "it still runs, then stop again. Stop without SubagentHandback while "
        "you wait. If you already handed back, the main session has that "
        "report; when the job ends, call SubagentHandback again with the final "
        f"result. {REPORT} For jobs that may run past 20 "
        "minutes, start them detached instead of with run_in_background, so a "
        "handoff does not leave you parked until they end: "
        "`nohup setsid sh -c '<cmd> > <log> 2>&1; echo $? > <done-file>' "
        ">/dev/null 2>&1 &` returns at once.",
        {**entry, "waited": int(waited)},
    )


if __name__ == "__main__":
    sys.exit(main())
