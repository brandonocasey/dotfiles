#!/usr/bin/env python3
"""PreToolUse guard for SendMessage: no late continuations of stopped sub-agents.

A sub-agent's prompt cache expires 5 minutes after its last request. Messaging
one that stopped longer ago rewrites its whole context at the cache-write price,
which costs more than a fresh agent given the earlier results as file paths.
Messages to a running agent, to one with a small context, and from sub-agents pass.

Exit 2 cancels the call and shows the message to the model.
"""

import json
import os
import re
import sys
import time
from datetime import datetime

IDLE_SECONDS = 5 * 60
# Below this, a rewrite costs about what a fresh agent's first request does.
MIN_CONTEXT = 50_000
TAIL_BYTES = 4_000_000
INTERRUPT = "[Request interrupted by user"


def entries(path: str) -> list[dict]:
    """The transcript's last entries; a long transcript is read from its tail."""
    try:
        with open(path, "rb") as f:
            f.seek(0, os.SEEK_END)
            f.seek(max(0, f.tell() - TAIL_BYTES))
            lines = f.read().decode("utf-8", "replace").splitlines()
    except OSError:
        return []
    out = []
    for line in lines:
        try:
            out.append(json.loads(line))
        except ValueError:
            continue  # also the partial first line of a tail read
    return out


def parts(entry: dict) -> list[dict]:
    content = (entry.get("message") or {}).get("content")
    return [p for p in content if isinstance(p, dict)] if isinstance(content, list) else []


def context(entry: dict) -> int:
    usage = (entry.get("message") or {}).get("usage") or {}
    return sum(usage.get(k) or 0 for k in (
        "input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))


def interrupted(entry: dict) -> bool:
    """TaskStop or Escape leaves this user entry last in the transcript."""
    content = (entry.get("message") or {}).get("content")
    texts = [content] if isinstance(content, str) else [
        str(p.get("text", "")) for p in parts(entry) if p.get("type") == "text"]
    return any(t.startswith(INTERRUPT) for t in texts)


def running(log: list[dict]) -> bool:
    """Whether the agent's last turn is still going or a newer message woke it."""
    users = [e for e in log if e.get("type") == "user"]
    if users and interrupted(users[-1]):
        return False
    # Error turns are <synthetic> assistant entries; they end a turn too.
    last = next((i for i in range(len(log) - 1, -1, -1) if log[i].get("type") == "assistant"), None)
    if last is None:
        return True
    calls = [p for p in parts(log[last]) if p.get("type") == "tool_use"]
    handbacks = {p.get("id") for p in calls if p.get("name") == "SubagentHandback"}
    if any(p.get("name") != "SubagentHandback" for p in calls):
        return True  # a tool call is still running
    for e in log[last + 1:]:
        if e.get("type") != "user":
            continue
        results = [p for p in parts(e) if p.get("type") == "tool_result"]
        if not results or any(p.get("tool_use_id") not in handbacks for p in results):
            return True
    return False


def last_stop(path: str) -> tuple[float, int] | None:
    """(time, context tokens) of a stopped agent's last real request; None while it runs."""
    log = entries(path)
    # The cache was last touched by a real request: <synthetic> error entries report 0 tokens.
    real = next((e for e in reversed(log) if e.get("type") == "assistant" and e.get("timestamp")
                 and (e.get("message") or {}).get("model") != "<synthetic>" and context(e)), None)
    if real is None or running(log):
        return None
    stamp = datetime.fromisoformat(real["timestamp"].replace("Z", "+00:00")).timestamp()
    return stamp, context(real)


def main() -> int:
    data = json.load(sys.stdin)
    if data.get("agent_id"):
        return 0  # a sub-agent writing to the main session
    to = str((data.get("tool_input") or {}).get("to") or "")
    transcript = data.get("transcript_path") or ""
    if not re.fullmatch(r"[A-Za-z0-9_-]+", to) or not transcript.endswith(".jsonl"):
        return 0
    path = os.path.join(transcript[:-len(".jsonl")], "subagents", f"agent-{to}.jsonl")
    stop = last_stop(path)
    if not stop:
        return 0
    idle, context = time.time() - stop[0], stop[1]
    if idle < IDLE_SECONDS or context < MIN_CONTEXT:
        return 0
    print(
        f"continue-guard: agent {to} stopped {int(idle // 60)} minutes ago, so its "
        f"prompt cache has expired; this message would rewrite its whole "
        f"{context // 1000}k-token context. Spawn a fresh agent of the same role "
        "instead and pass its earlier results as file paths.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
