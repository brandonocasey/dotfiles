"""Exercise the registered Codex title hook against an isolated tmux server."""
import fcntl
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parents[2]
HOOK = REPO / "home/dot_claude/hooks/executable_agent-tmux-session.sh"
HOOKS = json.loads((REPO / "home/dot_codex/hooks.json").read_text())["hooks"]
SCRATCH = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"


@unittest.skipUnless(shutil.which("tmux") and shutil.which("jq"), "tmux and jq required")
class CodexTmuxSessionTests(unittest.TestCase):
    def setUp(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="codex-tmux-test-", dir=SCRATCH)
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        # Unix socket paths MUST fit the platform limit even with a long XDG root.
        sockets = tempfile.TemporaryDirectory(prefix="agent-tmux-", dir="/tmp")
        self.addCleanup(sockets.cleanup)
        self.socket = Path(sockets.name) / "tmux.sock"
        self.env = dict(os.environ, HOME=str(self.home), CODEX_HOME=str(self.home / ".codex"),
                        XDG_CACHE_HOME=str(self.home / ".cache"),
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_STATE_HOME=str(self.home / ".local/state"),
                        TMUX="", TMUX_PANE="", SSH_TTY="", CLAUDECODE="")
        self.tmux("new-session", "-d", "-s", "original", "sleep 60")
        self.addCleanup(lambda: self.tmux("kill-server", check=False))
        pane = self.tmux("display-message", "-p", "#{pane_id}").strip()
        self.env.update(TMUX=f"{self.socket},0,0", TMUX_PANE=pane)
        target = self.home / ".claude/hooks/agent-tmux-session.sh"
        target.parent.mkdir(parents=True)
        shutil.copyfile(HOOK, target)
        self.index = self.home / ".codex/session_index.jsonl"
        self.index.parent.mkdir()
        self.parents = []
        self.addCleanup(self.stop_parents)
        driver = self.home / "codex"
        driver.write_text("#!/usr/bin/python3\n" +
                          "import json, subprocess, sys\n" +
                          "for line in sys.stdin:\n" +
                          "    request = json.loads(line)\n" +
                          "    result = subprocess.run(['sh', '-c', request['command']], " +
                          "input=json.dumps(request['payload']), text=True, capture_output=True, timeout=5)\n" +
                          "    print(json.dumps({'code': result.returncode, 'stderr': result.stderr}), flush=True)\n")
        driver.chmod(0o755)
        self.driver = driver
        self.parent = self.start_parent()

    def tmux(self, *args, check=True):
        return subprocess.run(["tmux", "-S", str(self.socket), *args], env=self.env,
                              text=True, capture_output=True, check=check, timeout=5).stdout

    def start_parent(self, pane=None):
        env = dict(self.env)
        if pane:
            env["TMUX_PANE"] = pane
        parent = subprocess.Popen([str(self.driver)], env=env, text=True,
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        self.parents.append(parent)
        return parent

    def stop_parents(self):
        for parent in self.parents:
            if parent.poll() is None:
                parent.stdin.close()
                parent.wait(timeout=5)
            parent.stdout.close()

    def fire(self, sid="one", event="SessionStart", parent=None):
        command = next(hook["command"] for group in HOOKS[event] for hook in group["hooks"]
                       if "agent-tmux-session.sh codex" in hook["command"])
        payload = dict(session_id=sid, hook_event_name=event, source="startup",
                       transcript_path=str(self.home / f"{sid}.jsonl"), cwd=str(self.home))
        parent = parent or self.parent
        parent.stdin.write(json.dumps(dict(command=command, payload=payload)) + "\n")
        parent.stdin.flush()
        self.assertEqual(json.loads(parent.stdout.readline()), dict(code=0, stderr=""))

    def title(self, value, sid="one"):
        with self.index.open("a") as stream:
            stream.write(json.dumps(dict(id=sid, thread_name=value)) + "\n")

    def name(self):
        return self.tmux("display-message", "-p", "-t", self.env["TMUX_PANE"], "#{session_name}").strip()

    def wait_name(self, expected):
        deadline = time.monotonic() + 4
        while time.monotonic() < deadline:
            if self.name() == expected:
                return
            time.sleep(0.03)
        self.assertEqual(self.name(), expected)

    def test_title_created_after_startup_and_idle_rename(self):
        self.fire()
        self.title("Fix late title")
        self.wait_name("Fix late title")
        self.title("Renamed while idle")
        self.wait_name("Renamed while idle")

    def test_resume_supersedes_previous_session(self):
        self.title("First session")
        self.fire()
        self.wait_name("First session")
        self.title("Second session", "two")
        self.fire("two")
        self.wait_name("Second session")
        self.title("Stale first title")
        self.title("Current second title", "two")
        self.wait_name("Current second title")
        time.sleep(1.2)
        self.assertEqual(self.name(), "Current second title")

    def test_active_pane_selects_session_title(self):
        self.title("First pane")
        self.fire()
        self.wait_name("First pane")
        pane = self.tmux("split-window", "-d", "-P", "-F", "#{pane_id}", "sleep 60").strip()
        self.title("Second pane", "two")
        self.fire("two", parent=self.start_parent(pane))
        time.sleep(1.2)
        self.assertEqual(self.name(), "First pane")
        self.tmux("select-pane", "-t", pane)
        self.wait_name("Second pane")
        self.tmux("select-pane", "-t", self.env["TMUX_PANE"])
        self.wait_name("First pane")

    def test_fast_pane_switch_restores_title_between_watcher_ticks(self):
        self.stop_parents()
        trace = self.home / "ticks.jsonl"
        bindir = self.home / "bin"
        bindir.mkdir()
        wrapper = bindir / "tmux"
        gate = self.home / "first-ticks.lock"
        wrapper.write_text("#!/usr/bin/python3\nimport fcntl, json, os, subprocess, sys, time\n"
                           "tick = sys.argv[-1].startswith('#{pane_active} #{window_active}')\n"
                           f"if tick and os.environ['TMUX_PANE'] == {self.env['TMUX_PANE']!r}:\n"
                           f"    gate = open({str(gate)!r}, 'a')\n"
                           "    fcntl.flock(gate, fcntl.LOCK_SH)\n"
                           f"result = subprocess.run([{shutil.which('tmux')!r}, *sys.argv[1:]], capture_output=True, timeout=5)\n"
                           "if tick:\n"
                           f"    with open({str(trace)!r}, 'a') as stream:\n"
                           "        stream.write(json.dumps(dict(pane=os.environ['TMUX_PANE'], output=result.stdout.decode())) + '\\n')\n"
                           "sys.stdout.buffer.write(result.stdout)\nsys.stderr.buffer.write(result.stderr)\n"
                           "sys.exit(result.returncode)\n")
        wrapper.chmod(0o755)
        self.env["PATH"] = str(bindir) + os.pathsep + self.env["PATH"]

        def drain():
            # Watchers outlive their parent by one tick and still write under HOME,
            # so wait for them before the temp dir is removed.
            self.stop_parents()
            deadline = time.monotonic() + 5
            while (subprocess.run(["pgrep", "-f", str(self.home)], capture_output=True).returncode == 0
                   and time.monotonic() < deadline):
                time.sleep(0.05)

        self.addCleanup(drain)
        self.parent = self.start_parent()
        first = self.env["TMUX_PANE"]
        second = self.tmux("split-window", "-d", "-P", "-F", "#{pane_id}", "sleep 60").strip()

        def ticks(pane):
            if not trace.exists():
                return []
            return [row for line in trace.read_text().splitlines()
                    if (row := json.loads(line))["pane"] == pane]

        self.title("First pane")
        self.title("Second pane", "two")
        self.fire()
        self.wait_name("First pane")
        time.sleep(0.5)
        self.fire("two", parent=self.start_parent(second))
        deadline = time.monotonic() + 4
        while len(ticks(first)) < 2 and time.monotonic() < deadline:
            time.sleep(0.01)
        self.assertGreaterEqual(len(ticks(first)), 2)
        time.sleep(0.1)
        # Hold first-pane ticks until the test switches back, so none reads the
        # pane while it is inactive.
        with gate.open("a") as held:
            fcntl.flock(held, fcntl.LOCK_EX)
            self.tmux("select-pane", "-t", second)
            self.wait_name("Second pane")
            self.tmux("select-pane", "-t", first)
        self.wait_name("First pane")
        self.assertTrue(all(row["output"].split()[:2] == ["1", "1"] for row in ticks(first)))

    def test_manual_name_survives_until_title_changes(self):
        self.title("Agent title")
        self.fire()
        self.wait_name("Agent title")
        self.tmux("rename-session", "Manual name")
        time.sleep(1.2)
        self.assertEqual(self.name(), "Manual name")
        self.title("Changed agent title")
        self.wait_name("Changed agent title")

    def test_duplicate_and_unsafe_title(self):
        self.tmux("new-session", "-d", "-s", "Fix v1_2 issue", "sleep 60")
        self.title("Fix v1.2: #issue!")
        self.fire()
        self.wait_name("Fix v1_2 issue (2)")

    def test_partial_index_recovers(self):
        self.index.write_text('{"id":')
        self.fire()
        self.index.write_text('{"id":\n{"id":"one","thread_name":"Recovered title"}\n')
        self.wait_name("Recovered title")

    def test_empty_and_invalid_titles_wait_for_valid_title(self):
        self.index.write_text('{"id":"one","thread_name":null}\n')
        self.fire()
        self.title("")
        time.sleep(1.2)
        self.assertEqual(self.name(), "original")
        self.title("Valid title")
        self.wait_name("Valid title")

    def test_claude_custom_title_still_wins(self):
        transcript = self.home / "claude.jsonl"
        transcript.write_text('{"type":"ai-title","aiTitle":"Automatic"}\n'
                              '{"type":"custom-title","customTitle":"Claude custom title"}\n')
        subprocess.run(["sh", str(self.home / ".claude/hooks/agent-tmux-session.sh"), "claude"],
                       input=json.dumps(dict(session_id="claude", transcript_path=str(transcript))),
                       text=True, env=self.env, check=True, timeout=5)
        self.assertEqual(self.name(), "Claude custom title")

    def test_parent_exit_stops_syncing(self):
        self.title("Before exit")
        self.fire()
        self.wait_name("Before exit")
        self.parent.stdin.close()
        self.parent.wait(timeout=5)
        self.title("After exit")
        time.sleep(1.2)
        self.assertEqual(self.name(), "Before exit")


if __name__ == "__main__":
    unittest.main()
