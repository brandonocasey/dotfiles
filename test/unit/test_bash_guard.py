"""Check the Bash PreToolUse guard hook blocks, fixes and allows the commands it should."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
HOOK = REPO / "home/dot_claude/hooks/executable_bash-guard.py"


class GuardTestCase(unittest.TestCase):
    fields = {}  # more hook input, such as cwd and session_id

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="bash-guard-")
        root = Path(self.directory.name)
        self.env = dict(os.environ, HOME=str(root / "home"), XDG_CONFIG_HOME=str(root / "config"),
                        XDG_CACHE_HOME=str(root / "cache"), XDG_STATE_HOME=str(root / "state"),
                        TMPDIR=str(root))
        self.env.pop("AGENT_HANDOFF", None)

    def tearDown(self):
        self.directory.cleanup()

    def run_hook(self, command, background=False):
        """Run the hook as Claude Code does: JSON on stdin, exit 2 plus stderr to block."""
        tool_input = {"command": command, "run_in_background": background}
        payload = {"tool_name": "Bash", "tool_input": tool_input, **self.fields}
        return subprocess.run([sys.executable, "-I", str(HOOK)], env=self.env, capture_output=True, text=True,
                              input=json.dumps(payload), timeout=30)

    def assertBlocked(self, command, hint):
        result = self.run_hook(command)
        self.assertEqual(result.returncode, 2, f"{command!r} was not blocked: {result.stderr}")
        self.assertTrue(result.stderr.startswith("bash-guard: "), result.stderr)
        self.assertIn(hint, result.stderr, command)

    def assertAllowed(self, command):
        result = self.run_hook(command)
        self.assertEqual(result.returncode, 0, f"{command!r} was blocked: {result.stderr}")
        self.assertEqual(result.stderr, "")
        self.assertEqual(result.stdout, "", f"{command!r} was changed")

    def assertFixed(self, command, expected, background=False, note="", result=None):
        """The hook lets the call run as expected, with no permission decision, so
        permission rules and auto mode still check the fixed command."""
        result = result or self.run_hook(command)
        self.assertEqual(result.returncode, 0, f"{command!r} was blocked: {result.stderr}")
        output = json.loads(result.stdout)["hookSpecificOutput"]
        self.assertEqual(output["hookEventName"], "PreToolUse")
        self.assertNotIn("permissionDecision", output)
        self.assertEqual(output["updatedInput"]["command"], expected, command)
        self.assertEqual(output["updatedInput"]["run_in_background"], background, command)
        self.assertTrue(output["additionalContext"].startswith("bash-guard changed this Bash call"))
        self.assertIn(note, output["additionalContext"])


class ExistingBehaviorTests(GuardTestCase):
    def test_foreground_sleep_runs_in_background(self):
        self.assertFixed("sleep 30", "sleep 30", background=True, note="It slept in the foreground.")

    def test_background_sleep_is_allowed(self):
        self.assertTrue(self.run_hook("sleep 30", background=True).returncode == 0)


class SleepPollTests(GuardTestCase):
    def test_sleep_then_check_runs_in_background(self):
        for command in ("sleep 19; tail -3 run.log", "sleep 15 && cat out.txt",
                        "sleep 15; cd /w; tail -2 a.log | cut -c1-80", "sleep 10; [ -f done ] && echo ok",
                        "sleep 18; ls -la /w/.cache", "sleep 12; rg -c ok run.log",
                        "sleep 15; sed -n '1,40p' run.log", "sleep 15; [[ -s run.log ]] && echo ok",
                        "sleep 15; if grep -q PASS run.log; then echo ok; fi", "sleep 15; jq .status out.json"):
            with self.subTest(command=command):
                self.assertFixed(command, command, background=True, note="wait for its exit notification")

    def test_short_or_unchecked_sleeps_are_allowed(self):
        for command in ("sleep 5; tail -3 run.log", "sleep 15", "sleep 15 && curl -s localhost:3000",
                        "tail -3 run.log; sleep 15", "echo 'sleep 15; cat x'",
                        "sleep 15 && curl -s localhost:3000 | head -20", "sleep 10 && ./test.sh",
                        "sleep 10; ./scripts/test-e2e.sh", "sleep 12; cd /repo/test && make"):
            with self.subTest(command=command):
                self.assertAllowed(command)

    def test_chained_and_looped_sleeps_run_in_background(self):
        self.assertFixed("sleep 19; sleep 19; sleep 19", "sleep 19; sleep 19; sleep 19", background=True)
        self.assertFixed("for i in 1 2 3; do sleep 19; done; ls", "for i in 1 2 3; do sleep 19; done; ls",
                         background=True, note="foreground polling loop")

    def test_waits_with_an_unfixable_problem_stay_blocked(self):
        # The kill has no safe fix, so the whole call is blocked with every message.
        self.assertBlocked("sleep 30; pkill node", "Foreground sleep")
        self.assertBlocked("sleep 30; pkill node", "in every session")

    def test_background_sleep_then_check_is_allowed(self):
        self.assertEqual(self.run_hook("sleep 19; tail run.log", background=True).returncode, 0)


class ZshEqualsTests(GuardTestCase):
    def test_unquoted_equals_words_are_quoted(self):
        for command, expected in (("echo ===", "echo '==='"), ("echo ==== done", "echo '====' done"),
                                  ("echo =foo", "echo '=foo'"), ("ls; echo =====", "ls; echo '====='"),
                                  ("true && echo === x ===", "true && echo '===' x '==='"),
                                  ("echo a\necho ===", "echo a\necho '==='"),
                                  ("echo =foo>out", "echo '=foo'>out"),
                                  ("cat <<EOF\n===\nEOF\necho ===", "cat <<EOF\n===\nEOF\necho '==='")):
            with self.subTest(command=command):
                self.assertFixed(command, expected, note="single-quoted")

    def test_equals_words_that_cannot_be_quoted_are_blocked(self):
        for command in ("echo ===\\\n", "echo =$HOME", "echo =a'b'", 'echo ="x"'):
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
    def test_printed_exit_status_is_dropped(self):
        for command in ("make; echo rc=$?", 'make; echo "exit=$?"', "make; echo $?",
                        'make || printf "rc=%s\\n" "$?"', "make\necho rc=$?", "make && printf '%s\\n' $?",
                        "make; echo rc=$? >&2", "make; echo rc=$? 2>&1", "make; echo $? # > done",
                        "make ;  echo $?;"):
            with self.subTest(command=command):
                self.assertFixed(command, "make", note="echo of $? was removed")

    def test_printed_exit_status_without_a_safe_cut_is_blocked(self):
        # Alone there is nothing left to run; after & or | the cut would change the job.
        # Inside a group, substitution or quoted script, the cut would drop its closing
        # character, and after a heredoc it would drop the heredoc.
        for command in ("echo $?", "make & echo $?", "make | echo $?", "(cd sub && make; echo $?)",
                        "bash -c 'make; echo $?'", "out=`make; echo $?`",
                        "python3 - <<'PY'\nimport x\nPY\necho \"exit=$?\"",
                        "cat > f <<'EOF'\nx\nEOF\necho $?", "bash -c 'make\necho $?'",
                        'bash -c "make\necho $?"', "make && \\\n  echo \"exit=$?\"", "make \\\n && echo $?",
                        "server > log 2>&1 &; echo $?"):
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
    def test_tools_without_toolsearch_gets_it(self):
        for command in ("claude -p 'hi' --tools Bash,Read", "claude-two -p --tools=Read,Grep 'x'",
                        "cd /tmp && claude -p --tools Bash 'x'",
                        "FOO=1 claude -p --tools Bash 'x'", "claude -p \\\n  --tools Bash \\\n  'x'",
                        "claude -p 'x' --tools Bash 2>&1 | tail -5", "timeout 300 claude -p --tools Bash 'x'",
                        "nohup claude -p --tools Bash 'x' > log 2>&1 &", "timeout -k 5 5m claude -p --tools Bash x",
                        "nohup setsid sh -c 'claude -p --tools Bash x > log 2>&1' &",
                        "claude -p --tools Bash Read 'x'", "claude -pc --tools Bash x",
                        "claude -p<r.md --tools Bash", "claude -p --tools \\\n  Bash x"):
            with self.subTest(command=command):
                expected = re.sub(r"(--tools(?:=|\s|\\\n)+)([^\s'\"]+)", r"\1\2,ToolSearch", command, count=1)
                self.assertFixed(command, expected, note="ToolSearch was added")
        self.assertFixed('claude --print --tools "Bash Read" hi', 'claude --print --tools "Bash Read,ToolSearch" hi')

    def test_tools_that_cannot_take_toolsearch_are_blocked(self):
        for command in ('claude -p --tools "" x', "claude -p --tools $TOOLS x", "claude -p --tools"):
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

    def test_handoff_session_cannot_start_claude(self):
        self.env["AGENT_HANDOFF"] = "1"
        for command in ("claude -p --model sonnet --append-system-prompt-file h.md --output-format json"
                        " < r.md > o.json 2> o.err",
                        "D=.cache/h && claude -p --model sonnet < $D/request.md > $D/o.json",
                        "cd app && claude --print 'x'", "nohup claude -p x > log 2>&1 &",
                        "AGENT_HANDOFF=1 claude -p --model sonnet < r.md", "claude --print=x",
                        "claude -pc x", "claude -cp x", "res=$(cat r.md | claude -p)", "claude -p<r.md",
                        "claude -p>o.json < r.md", "claude -p\\\n  --model sonnet < r.md", "claude -p\"x\"",
                        "claude -p'x'", "claude -p2>&1", "claude -p`cat r.md`", "claude -p$'x'"):
            with self.subTest(command=command):
                self.assertBlocked(command, "handoff session")
        # handoff.md starts the session with run_in_background, so that path must block too.
        result = self.run_hook("claude -p --model sonnet < r.md > o.json", background=True)
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("handoff session", result.stderr)

    def test_handoff_session_allows_other_commands(self):
        self.env["AGENT_HANDOFF"] = "1"
        for command in ("git status", "echo claude -p", "grep -c 'claude -p' log", "claude --version",
                        "claude --permission-mode plan", "claude -c", "claude --print-config",
                        "claude --plugin-dir x"):
            with self.subTest(command=command):
                self.assertAllowed(command)

    def test_main_session_can_start_handoff(self):
        self.assertAllowed("AGENT_HANDOFF=1 claude -p --model sonnet --append-system-prompt-file h.md < r.md > o.json")


class KillScopeTests(GuardTestCase):
    fields = {"cwd": "/work/repo/.worktrees/fix-a", "session_id": "5e55-1d"}

    def test_kills_by_name_are_blocked(self):
        # The first three stopped other A/B runs, whose prompts were on their command lines.
        for command in ("pkill -f '[u]nittest discover'; sleep 1", "pkill -f '[s]tock'; true",
                        "pkill -f '[o]rchestrate/references/handoff.md'", "pkill node", "pkill -9 -f '[v]ite'",
                        "sudo pkill -f '[n]ode'", "pkill -f '[/]work/repo/other/server.js'",
                        "pgrep -f '[n]ode' | xargs kill", "pgrep -f '[n]ode' | xargs -r kill -9",
                        "kill $(pgrep -f '[n]ode')", "kill -9 `pgrep -f '[n]ode'`", "killall node",
                        "bash -c 'pkill -f [n]ode'", "killall Dock",
                        # Paths are shared too (a main checkout, $HOME), and | widens any pattern.
                        "pkill -f '[/]work/repo/.worktrees/fix-a/server.js'",
                        "pkill -f '[n]ode /tmp/claude/5e55-1d/scratchpad/s.js'",
                        "pkill -f '[v]ite|[/]work/repo/.worktrees/fix-a/x'", "echo x | xargs pkill -f node",
                        "xargs -r pkill -f '[n]ode' < names",
                        # A value attached to -u is not option letters: the s in bcasey is not -s.
                        "pkill -ubcasey node", "pkill -uroot -f '[n]ode'", "pkill -f '[n]ode' -ubcasey"):
            with self.subTest(command=command):
                self.assertBlocked(command, "in every session")

    def test_scoped_kills_are_allowed(self):
        for command in ("kill $PID", "kill 1234", "kill %1", "pkill -P $$", "pkill -F /work/server.pid",
                        "pkill -P 123 -f '[n]ode'", "pkill --parent=123 -f '[n]ode'",
                        "pkill -P123 node", "pkill -fP123 '[n]ode'", "pkill -F/work/s.pid", "pkill -u root -P 1 node",
                        "pgrep -f '[n]ode'", "pgrep -fl '[n]ode'",
                        "pgrep -f '[n]ode' | wc -l", "kill -0 $(pgrep -f '[n]ode')",
                        "echo 'pkill node'", "rg -n pkill hooks", "grep -c killall log"):
            with self.subTest(command=command):
                self.assertAllowed(command)

    def test_broad_kills_get_no_bracket_hint(self):
        # Bracketing stops a kill matching its own shell but not other sessions, so it is no fix.
        for command in ("pkill -f node", "pgrep -f node | xargs kill", "kill $(pgrep -f node)"):
            with self.subTest(command=command):
                result = self.run_hook(command)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn("in every session", result.stderr)
                self.assertNotIn("Bracket one character", result.stderr)

    def test_options_after_the_pattern(self):
        # Linux procps reads options anywhere. macOS reads words after the pattern as more
        # patterns, so there -P 123 widens the kill to every process holding "-P" or "123".
        for command in ("pkill -f '[n]ode' -P 123", "pkill '[n]ode' --parent=123"):
            with self.subTest(command=command):
                if sys.platform.startswith("linux"):
                    self.assertAllowed(command)
                else:
                    self.assertBlocked(command, "put options such as -P before it")

    def test_other_pkill_forms_get_the_bracket(self):
        # A pgrep only lists, and a pkill scoped by -P stops only that parent's children.
        for command, expected in (("pkill -P 123 -f node", "pkill -P 123 -f '[n]ode'"),
                                  ("pgrep -f node", "pgrep -f '[n]ode'"),
                                  ("pgrep -fl 'vite dev' | head", "pgrep -fl '[v]ite dev' | head"),
                                  ('pgrep -f "mise run"', 'pgrep -f "[m]ise run"')):
            with self.subTest(command=command):
                self.assertFixed(command, expected, note="cannot match its own shell")

    def test_self_matches_that_brackets_cannot_fix_are_blocked(self):
        # An unscoped pkill the broad-kill check missed (after if, or sudo -u root)
        # would still kill every match once bracketed, so it stays blocked.
        for command, hint in (("pgrep -f '[n]ode'; node x.js", "pgrep -f"), ("pgrep -f 'a'\"b\"", "pgrep -f"),
                              ("sudo -u root pkill -f node", "in every session"),
                              ("if pkill -f node; then echo ok; fi", "in every session"),
                              # Quoting would stop $VAR and ~ from expanding.
                              ("pgrep -fl $PWD", "pgrep -f"), ("pgrep -fl ~/x/server", "pgrep -f")):
            with self.subTest(command=command):
                self.assertBlocked(command, hint)


class AgtWaitTests(GuardTestCase):
    def test_foreground_wait_runs_in_background(self):
        for command in ("agt wait --timeout 600 -- test -f done", "agt ci wait '!12'",
                        "cd /w && agt ci wait --help-me"):
            self.assertFixed(command, command, background=True, note="agt wait in the foreground")

    def test_detached_wait_drops_its_ampersand(self):
        # With & the background task's shell exits at once, and its notification with it.
        self.assertFixed("agt wait --timeout 270 -- test -e done &", "agt wait --timeout 270 -- test -e done",
                         background=True)
        self.assertFixed("nohup agt wait -- test -e d > log 2>&1 &", "nohup agt wait -- test -e d > log 2>&1",
                         background=True)
        self.assertFixed("make && agt wait -- test -e d", "make && agt wait -- test -e d", background=True)
        # Another job's & stays; an & before more commands would still let the shell exit early.
        self.assertFixed("agt wait -- test -e d; server &", "agt wait -- test -e d; server &", background=True)
        self.assertBlocked("agt wait -- test -e d & echo started", "agt wait in the foreground")
        # The & of a pipeline or && chain holding the wait detaches the wait too.
        self.assertFixed("agt wait -- x | tee l &", "agt wait -- x | tee l", background=True)
        self.assertFixed("agt wait -- x && echo done &", "agt wait -- x && echo done", background=True)
        # So does the & after a group or -c script holding it.
        self.assertFixed("(agt wait -- test -e d; echo ready) &", "(agt wait -- test -e d; echo ready)",
                         background=True)
        self.assertFixed("agt wait -- sh -c 'test -e a; test -e b' &", "agt wait -- sh -c 'test -e a; test -e b'",
                         background=True)
        self.assertBlocked("(agt wait -- test -e d; echo ready) & echo started", "agt wait in the foreground")

    def test_several_fixes_apply_together(self):
        self.assertFixed("agt ci wait '!12'; echo ===; echo $?", "agt ci wait '!12'; echo '==='",
                         background=True, note="Command run: agt ci wait '!12'; echo '==='")

    def test_help_is_allowed(self):
        for command in ("agt ci wait --help", "agt wait -h", "agt ci wait --help 2>&1 | rg -n sha"):
            self.assertAllowed(command)


class SubagentTimeoutTests(GuardTestCase):
    def run_call(self, timeout: int | None, agent_id: str | None = "a1", background: bool = False):
        tool_input = {"command": "npm test", "timeout": timeout, "run_in_background": background}
        payload = {"tool_name": "Bash", "tool_input": tool_input}
        if agent_id:
            payload["agent_id"] = agent_id
        return subprocess.run([sys.executable, "-I", str(HOOK)], env=self.env, capture_output=True, text=True,
                              input=json.dumps(payload), timeout=30)

    def test_long_subagent_foreground_call_runs_in_background(self):
        self.assertFixed("npm test", "npm test", background=True, result=self.run_call(590000),
                         note="9.8-minute timeout would outlast")

    def test_short_or_background_or_main_calls_are_allowed(self):
        for name, outcome in (("short", self.run_call(270000)), ("default", self.run_call(None)),
                              ("background", self.run_call(590000, background=True)),
                              ("main session", self.run_call(590000, agent_id=None))):
            with self.subTest(name):
                self.assertEqual(outcome.returncode, 0, outcome.stderr)


if __name__ == "__main__":
    unittest.main()
