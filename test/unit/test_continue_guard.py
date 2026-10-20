"""Check the SendMessage guard blocks late continuations of stopped sub-agents only."""
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
HOOK = REPO / "home/dot_claude/hooks/executable_continue-guard.py"
BIG = {"input_tokens": 10, "cache_read_input_tokens": 150_000, "cache_creation_input_tokens": 2_000}


def stamp(minutes_ago):
    return (datetime.now(timezone.utc) - timedelta(minutes=minutes_ago)).isoformat().replace("+00:00", "Z")


def assistant(minutes_ago, content, usage=BIG):
    return {"type": "assistant", "timestamp": stamp(minutes_ago),
            "message": {"usage": usage, "content": content}}


def result(tool_use_id):
    return {"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": tool_use_id}]}}


class ContinueGuardTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="continue-guard-")
        root = Path(self.directory.name)
        self.transcript = root / "session.jsonl"
        self.agents = root / "session" / "subagents"
        self.agents.mkdir(parents=True)

    def tearDown(self):
        self.directory.cleanup()

    def run_hook(self, log, sender=None):
        (self.agents / "agent-a1.jsonl").write_text("".join(json.dumps(e) + "\n" for e in log))
        payload = {"tool_name": "SendMessage", "transcript_path": str(self.transcript),
                   "tool_input": {"to": "a1", "message": "next"}}
        if sender:
            payload["agent_id"] = sender
        return subprocess.run([sys.executable, "-I", str(HOOK)], capture_output=True, text=True,
                              input=json.dumps(payload), timeout=30)

    def test_late_continuation_is_blocked(self):
        for log in ([assistant(12, [{"type": "text", "text": "done"}])],
                    [assistant(12, [{"type": "tool_use", "id": "h", "name": "SubagentHandback"}]), result("h")]):
            with self.subTest(log=log):
                outcome = self.run_hook(log)
                self.assertEqual(outcome.returncode, 2, outcome.stderr)
                self.assertIn("stopped 12 minutes ago", outcome.stderr)
                self.assertIn("152k-token context", outcome.stderr)

    def test_recent_small_running_or_woken_agents_pass(self):
        text = [{"type": "text", "text": "done"}]
        woken = {"type": "user", "message": {"content": "more work"}}
        for log in ([assistant(2, text)],
                    [assistant(12, text, {"input_tokens": 20_000})],
                    [assistant(12, [{"type": "tool_use", "id": "b", "name": "Bash"}])],
                    [assistant(12, text), woken]):
            with self.subTest(log=log):
                self.assertEqual(self.run_hook(log).returncode, 0)

    def test_messages_from_subagents_and_unknown_agents_pass(self):
        self.assertEqual(self.run_hook([assistant(12, [{"type": "text", "text": "done"}])], sender="a2").returncode, 0)
        (self.agents / "agent-a1.jsonl").unlink(missing_ok=True)
        payload = {"tool_name": "SendMessage", "transcript_path": str(self.transcript), "tool_input": {"to": "zz"}}
        outcome = subprocess.run([sys.executable, "-I", str(HOOK)], capture_output=True, text=True,
                                 input=json.dumps(payload), timeout=30)
        self.assertEqual(outcome.returncode, 0)


if __name__ == "__main__":
    unittest.main()
