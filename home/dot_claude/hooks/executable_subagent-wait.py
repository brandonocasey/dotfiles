#!/usr/bin/env python3
"""SubagentStop hook: keep waiting subagents warm for 20 minutes, then hand off.

A subagent that stops while its own background shell job runs sits idle until
the job ends, and its 5-minute prompt cache expires. This hook makes it wake
every 4.5 minutes instead (one cheap cache read per wake), by requiring a
running `agt wait` waiter. After 20 minutes of waiting on the same jobs it
must write a handoff file and hand back with `HANDOFF: <path>`, so the main
session can wait for free and start a fresh agent from that file.

SubagentHandback delivers one report and ends the turn. The harness discards a
stop-hook block after a turn ended by a tool, so this hook can only steer
plain-text stops; after a handback it just records the outcome.

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
WAITER = re.compile(r"\bagt\s+wait\b")
HANDOFF = re.compile(r"HANDOFF:[*_`\s]*([^\s`*]+)")
REPORT = (
    "If you have SubagentHandback, it delivers one report only, so call it "
    "once, at the end; plain reply text does not reach the main session. "
    "Without it, your final plain reply is the report."
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


def parts(entry: dict) -> list:
    content = (entry.get("message") or {}).get("content")
    return [p for p in content if isinstance(p, dict)] if isinstance(content, list) else []


def result_text(part: dict) -> str:
    content = part.get("content")
    if isinstance(content, list):
        return " ".join(str(p.get("text", "")) for p in content if isinstance(p, dict))
    return str(content or "")


def handbacks(transcript: str) -> tuple[bool, str, bool, bool]:
    """(ended, message, delivered, final) for SubagentHandback calls.

    ended/message/delivered describe a handback that ended this turn. final
    means a delivered handback has no later coordinator message, so the
    agent's report is already out and its waits are over.
    """
    entries = []
    for line in transcript.splitlines():
        try:
            entries.append(json.loads(line))
        except ValueError:
            continue
    results = {p.get("tool_use_id"): p for e in entries for p in parts(e)
               if p.get("type") == "tool_result"}

    def delivered(call: dict) -> bool:
        p = results.get(call.get("id"))
        return not p or not (p.get("is_error") or re.search(
            r"Nothing was sent|\"success\"\s*:\s*false", result_text(p)))

    calls, last_assistant, last_delivered, last_coordinator = {}, None, None, None
    for i, e in enumerate(entries):
        if e.get("type") == "assistant":
            last_assistant = i
            for p in parts(e):
                if p.get("type") == "tool_use" and p.get("name") == "SubagentHandback":
                    calls[i] = p
                    if delivered(p):
                        last_delivered = i
        elif "coordinator" in (
            (e.get("origin") or {}).get("kind"),
            # Messages queued mid-turn arrive as attachments.
            ((e.get("attachment") or {}).get("origin") or {}).get("kind"),
        ):
            last_coordinator = i
    final = last_delivered is not None and (
        last_coordinator is None or last_coordinator < last_delivered)
    call = calls.get(last_assistant)
    if not call:
        return False, "", False, final
    return True, str((call.get("input") or {}).get("message") or ""), delivered(call), final


def handoff_file(text: str) -> str:
    found = HANDOFF.findall(text)
    path = os.path.expanduser(found[-1].rstrip(".,;:)]'\"")) if found else ""
    return path if path and os.path.isfile(path) else ""


def wait_keys(jobs: list[dict]) -> list[str]:
    """What is being waited on: work job ids, and waiter checks for detached jobs."""
    return sorted({
        "check:" + command.split(" -- ", 1)[-1].strip() if WAITER.search(command) else t["id"]
        for t in jobs for command in [t.get("command") or ""]
    })


def new_wait(keys: list[str], known: list[str]) -> bool:
    """A new work job, or a waiter check replacing another, starts a new wait.

    Adding the first waiter to a running job only arms the wait.
    """
    added = set(keys) - set(known)
    had_check = any(k.startswith("check:") for k in known)
    return any(not k.startswith("check:") or had_check for k in added)


def completed_tasks(transcript: str) -> set[str]:
    """Ids of background tasks whose notification says they exited 0.

    A waiter exits 0 only when its check passed, so its job is done even
    when the next job reuses the same check.
    """
    return set(re.findall(
        r"<task-id>(\w+)</task-id>(?:(?!</task-notification>)[\s\S])*?"
        r"<status>completed</status>", transcript))


def clear(state_file: str) -> None:
    for path in (state_file, state_file + ".plain-handoff"):
        if os.path.exists(path):
            os.remove(path)


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

    ended, handback, delivered, final = handbacks(transcript)
    if ended:
        # A block would be discarded; record what the handback did.
        handoff = handoff_file(handback) if delivered else ""
        if handoff or not jobs:
            clear(state_file)
        if jobs:
            decision = "handoff" if handoff else ("handed-back" if delivered else "handback-rejected")
            log({**entry, "decision": decision, "file": handoff})
        return 0
    if final:
        # The report is out; a later wake (waiter or job exit) must not
        # restart the wait or rewrite the handoff file.
        clear(state_file)
        if jobs:
            log({**entry, "decision": "after-handback"})
        return 0

    # Checked even with no tracked jobs: after a detached job's waiter is
    # stopped, nothing would wake the agent to resend a plain-text handoff.

    handoff = handoff_file(data.get("last_assistant_message") or "")
    if handoff:
        can_hand_back = ("SubagentHandback" in transcript
                         and "SubagentHandback is not available" not in transcript)
        # Ask once per handoff; stop_hook_active is no guide, since it stays
        # set after the forced-handoff block.
        asked = state_file + ".plain-handoff"
        if can_hand_back and not os.path.exists(asked):
            open(asked, "w").close()
            return block(
                "Plain reply text does not reach the main session. Send this "
                "report, ending with the HANDOFF line, through SubagentHandback; "
                "if it says your report was already delivered, use SendMessage.",
                {**entry, "file": handoff},
            )
        clear(state_file)
        log({**entry, "decision": "handoff", "file": handoff})
        return 0

    if not jobs:
        clear(state_file)
        return 0

    # The clock covers waits on the same work. A new job or done-check, or a
    # waiter that saw its check pass (work done between waits), starts a new
    # wait.
    now = time.time()
    keys = wait_keys(jobs)
    try:
        with open(state_file, encoding="utf-8") as f:
            state = json.load(f)
        since, known = float(state["since"]), state["jobs"]
        waiters = set(state.get("waiters") or [])
    except (OSError, ValueError, KeyError, TypeError):
        since, known, waiters = now, [], set()
    passed = waiters & completed_tasks(transcript)
    if new_wait(keys, known) or passed:
        since = now
    waiters = (waiters - passed) | {
        t["id"] for t in jobs if WAITER.search(t.get("command") or "")}
    with open(state_file, "w", encoding="utf-8") as f:
        json.dump({"since": since, "jobs": keys, "waiters": sorted(waiters)}, f)
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
            "done. Stop your agt wait waiter with TaskStop if you have it; "
            "otherwise leave it. Then end your report with the line "
            f"HANDOFF: {target}. {REPORT}",
            {**entry, "waited": int(waited)},
        )

    if any(WAITER.search(t.get("command") or "") for t in jobs):
        log({**entry, "decision": "allow-waiter", "waited": int(waited)})
        return 0

    return block(
        "Your background job is still running, and an idle wait lets your "
        "prompt cache expire. Before stopping, start a waiter with "
        "run_in_background: true, e.g. `agt wait --timeout 270 -- test -e <done-file>`. "
        "It wakes you within 4.5 minutes; check the job, re-arm the waiter if "
        "it still runs, then stop again with a short plain-text note. "
        f"{REPORT} For jobs that may run past 20 "
        "minutes, start them detached instead of with run_in_background, so a "
        "handoff does not leave you parked until they end: "
        "`nohup setsid sh -c '<cmd> > <log> 2>&1; echo $? > <done-file>' "
        ">/dev/null 2>&1 &` returns at once.",
        {**entry, "waited": int(waited)},
    )


if __name__ == "__main__":
    sys.exit(main())
