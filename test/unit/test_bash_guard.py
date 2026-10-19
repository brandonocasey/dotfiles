"""Check the Bash PreToolUse guard hook blocks and allows the commands it should."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
HOOK = REPO / "home/dot_claude/hooks/executable_bash-guard.py"


class GuardTestCase(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="bash-guard-")
        root = Path(self.directory.name)
        self.env = dict(os.environ, HOME=str(root / "home"), XDG_CONFIG_HOME=str(root / "config"),
                        XDG_CACHE_HOME=str(root / "cache"), XDG_STATE_HOME=str(root / "state"),
                        TMPDIR=str(root))

    def tearDown(self):
        self.directory.cleanup()

    def run_hook(self, command, background=False):
        """Run the hook as Claude Code does: JSON on stdin, exit 2 plus stderr to block."""
        tool_input = {"command": command, "run_in_background": background}
        return subprocess.run([sys.executable, "-I", str(HOOK)], env=self.env, capture_output=True, text=True,
                              input=json.dumps({"tool_name": "Bash", "tool_input": tool_input}), timeout=30)

    def assertBlocked(self, command, hint):
        result = self.run_hook(command)
        self.assertEqual(result.returncode, 2, f"{command!r} was not blocked: {result.stderr}")
        self.assertTrue(result.stderr.startswith("bash-guard: "), result.stderr)
        self.assertIn(hint, result.stderr, command)

    def assertAllowed(self, command):
        result = self.run_hook(command)
        self.assertEqual(result.returncode, 0, f"{command!r} was blocked: {result.stderr}")
        self.assertEqual(result.stderr, "")


class ExistingBehaviorTests(GuardTestCase):
    def test_foreground_sleep_is_blocked(self):
        self.assertBlocked("sleep 30", "Foreground sleep")

    def test_background_sleep_is_allowed(self):
        self.assertTrue(self.run_hook("sleep 30", background=True).returncode == 0)


class SleepPollTests(GuardTestCase):
    def test_sleep_then_check_is_blocked(self):
        for command in ("sleep 19; tail -3 run.log", "sleep 15 && cat out.txt",
                        "sleep 15; cd /w; tail -2 a.log | cut -c1-80", "sleep 10; [ -f done ] && echo ok",
                        "sleep 18; ls -la /w/.cache", "sleep 12; rg -c ok run.log"):
            with self.subTest(command=command):
                self.assertBlocked(command, "Sleep-then-check polling")

    def test_short_or_unchecked_sleeps_are_allowed(self):
        for command in ("sleep 5; tail -3 run.log", "sleep 15", "sleep 15 && curl -s localhost:3000",
                        "tail -3 run.log; sleep 15", "echo 'sleep 15; cat x'"):
            with self.subTest(command=command):
                self.assertAllowed(command)

    def test_chained_and_looped_sleeps_are_blocked(self):
        self.assertBlocked("sleep 19; sleep 19; sleep 19", "(38s in all)")
        self.assertBlocked("for i in 1 2 3; do sleep 19; done; ls", "Foreground polling loop")

    def test_background_sleep_then_check_is_allowed(self):
        self.assertEqual(self.run_hook("sleep 19; tail run.log", background=True).returncode, 0)


class ZshEqualsTests(GuardTestCase):
    def test_unquoted_equals_words_are_blocked(self):
        for command in ("echo ===", "echo ==== done", "echo =foo", "ls; echo =====",
                        "true && echo === x ===", "echo a\necho ===", "echo ===\\\n"):
            with self.subTest(command=command):
                self.assertBlocked(command, "printf '--- %s\\n'")

    def test_allowed_equals_forms(self):
        for command in ("[ a = b ]", "[[ a == b ]]", "[[ $x == =foo ]] && echo ok", "echo '==='",
                        'echo "==="', "echo a==b", "git log --pretty=x", "FOO=bar env",
                        "echo \\===", "echo hi # === comment",
                        "cat <<'EOF'\n=== heading\nEOF", "cat <<EOF\n===\nEOF\necho done",
                        "(( count == 0 )) && echo ok", "echo $(( 2 == 2 ))",
                        "if (( a == b )); then echo ok; fi", "bash -c 'echo ==='"):
            with self.subTest(command=command):
                self.assertAllowed(command)


class ExitStatusEchoTests(GuardTestCase):
    def test_printed_exit_status_is_blocked(self):
        for command in ("make; echo rc=$?", 'make; echo "exit=$?"', "make; echo $?",
                        'make || printf "rc=%s\\n" "$?"', "make\necho rc=$?", "make && printf '%s\\n' $?",
                        "make; echo rc=$? >&2", "make; echo rc=$? 2>&1", "make; echo $? # > done"):
            with self.subTest(command=command):
                self.assertBlocked(command, "exit code")

    def test_status_in_tests_and_assignments_is_allowed(self):
        for command in ("make; rc=$?", "make; if [ $? -ne 0 ]; then exit 1; fi", "make || [ $? -eq 2 ]",
                        "make; exit $?", "echo '$?'", "echo done",
                        "cat <<EOF\nexit=$?\nEOF", "cat <<'EOF'\necho rc=$?\nEOF\necho ok",
                        'make > log 2>&1; echo "exit $?" >> log', "make; echo $? > done",
                        "make; printf '%s\\n' \"$?\" >>\"$LOG\"",
                        '(make; echo "exit $?") > log 2>&1 &', "{ make; echo $?; } > log",
                        'for f in a b; do make "$f"; echo "$f $?"; done',
                        'make > "$S/t.log" 2>&1; echo $? > "$S/t.done"',
                        "make; echo done # inspect $? later"):
            with self.subTest(command=command):
                self.assertAllowed(command)


class HeadlessClaudeTests(GuardTestCase):
    def test_tools_without_toolsearch_is_blocked(self):
        for command in ("claude -p 'hi' --tools Bash,Read", 'claude --print --tools "Bash Read" hi',
                        "claude-two -p --tools=Read,Grep 'x'", "cd /tmp && claude -p --tools Bash 'x'",
                        "FOO=1 claude -p --tools Bash 'x'", "claude -p \\\n  --tools Bash \\\n  'x'",
                        "claude -p 'x' --tools Bash 2>&1 | tail -5", "timeout 300 claude -p --tools Bash 'x'",
                        "nohup claude -p --tools Bash 'x' > log 2>&1 &", "timeout -k 5 5m claude -p --tools Bash x",
                        "nohup setsid sh -c 'claude -p --tools Bash x > log 2>&1' &",
                        "claude -p --tools Bash Read 'x'"):
            with self.subTest(command=command):
                self.assertBlocked(command, "ToolSearch")

    def test_allowed_claude_forms(self):
        for command in ("claude -p 'hi'", "claude -p --tools Bash,ToolSearch 'x'",
                        'claude --print --tools "Bash,ToolSearch,Read" x',
                        "claude -p --tools Bash --strict-mcp-config 'x'",
                        "claude --tools Bash", "claude --resume", "echo claude -p --tools Bash",
                        "echo 'claude -p --tools Bash'", "grep -p --tools Bash",
                        "claude -p --allowedTools Bash 'x'", "claude -p \"Does the --tools flag accept commas?\"",
                        "claude -p --tools default 'x'", "claude -p --tools Bash ToolSearch 'x'",
                        "timeout 300 claude -p --tools Bash,ToolSearch 'x'", "grep -c 'claude -p --tools Bash' log"):
            with self.subTest(command=command):
                self.assertAllowed(command)


if __name__ == "__main__":
    unittest.main()
