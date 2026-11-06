"""Exercise registered agent status hooks with an isolated tmux server."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parents[2]
TMUX = next((str(path) for path in (
    Path("/opt/homebrew/bin/tmux"),
    Path("/home/linuxbrew/.linuxbrew/bin/tmux"),
    Path("/usr/local/bin/tmux"),
) if path.is_file()), shutil.which("tmux"))
HOOKS = json.loads((REPO / "home/dot_codex/hooks.json").read_text())["hooks"]


@unittest.skipUnless(TMUX, "tmux is required")
class TmuxBellTests(unittest.TestCase):
    def setUp(self):
        scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
        scratch.mkdir(parents=True, exist_ok=True)
        self.directory = tempfile.TemporaryDirectory(prefix="tmux-bell-", dir=scratch)
        self.addCleanup(self.directory.cleanup)
        self.home = Path(self.directory.name)
        sockets = tempfile.TemporaryDirectory(prefix="tmux-bell-", dir="/tmp")
        self.addCleanup(sockets.cleanup)
        self.socket = str(Path(sockets.name) / "s")
        self.env = dict(os.environ, HOME=str(self.home), TMUX="", TMUX_PANE="",
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_CACHE_HOME=str(self.home / ".cache"),
                        XDG_STATE_HOME=str(self.home / ".state"),
                        PATH="/usr/bin:/bin", CLAUDECODE="", CLAUDE_CODE_SESSION_ATTENDED="1")
        self.tmux("-f", "/dev/null", "new-session", "-d", "-s", "test", "sleep 60")
        self.addCleanup(lambda: self.tmux("kill-server"))
        self.pane = self.tmux("display-message", "-p", "#{pane_id}")
        self.env.update(TMUX=f"{self.socket},0,0", TMUX_PANE=self.pane)
        hook = self.home / ".claude/hooks/tmux-bell.sh"
        hook.parent.mkdir(parents=True)
        shutil.copyfile(REPO / "home/dot_claude/hooks/executable_tmux-bell.sh", hook)
        client = self.home / ".config/tmux/scripts/tmux-client.sh"
        client.parent.mkdir(parents=True)
        shutil.copyfile(REPO / "home/dot_config/tmux/scripts/executable_tmux-client.sh", client)

    def tmux(self, *args):
        return subprocess.check_output([TMUX, "-S", self.socket, *args],
                                       env=self.env, text=True, timeout=5).strip()

    def fire(self, event):
        command = next(hook["command"] for group in HOOKS[event] for hook in group["hooks"]
                       if "tmux-bell.sh" in hook["command"])
        result = subprocess.run(["sh", "-c", command], env=self.env, text=True,
                                input=json.dumps(dict(hook_event_name=event, session_id="test")),
                                capture_output=True, timeout=5, check=True)
        self.assertEqual((result.stdout, result.stderr), ("", ""))

    def state(self):
        return self.tmux("show-options", "-pqv", "-t", self.pane, "@agent_state")

    def bell(self):
        return self.tmux("display-message", "-p", "#{window_bell_flag}")

    def wait_for(self, condition, seconds):
        deadline = time.monotonic() + seconds
        while not condition() and time.monotonic() < deadline:
            time.sleep(0.2)
        return condition()

    def wait_for_state(self, expected, seconds):
        self.wait_for(lambda: self.state() == expected, seconds)
        return self.state()

    def watchers(self):
        return [line for line in subprocess.check_output(["ps", "-A", "-o", "args="], text=True).splitlines()
                if "watch-codex" in line and str(self.home) in line]

    def start_codex(self, terminal_seconds):
        """Runs the registered Codex Stop hook in the pane under a process named
        codex. Like Codex, it keeps a server child on the pane's terminal; with
        terminal_seconds it also runs a command in a new session, like a
        background terminal."""
        codex = self.home / "bin/codex"
        codex.parent.mkdir(exist_ok=True)
        codex.symlink_to("/bin/sh")
        payload = self.home / "stop.json"
        payload.write_text(json.dumps(dict(hook_event_name="Stop", session_id="test")))
        command = next(hook["command"] for group in HOOKS["Stop"] for hook in group["hooks"]
                       if "tmux-bell.sh" in hook["command"])
        terminal = (f"/usr/bin/perl -MPOSIX -e 'setsid(); sleep {terminal_seconds}' & "
                    if terminal_seconds else "")
        self.tmux("respawn-pane", "-k", "-t", self.pane, "-e", f"HOOK={command}", "-e", f"PAYLOAD={payload}",
                  str(codex), "-c", f'/bin/sleep 20 & {terminal}sh -c "$HOOK" <"$PAYLOAD"; read -r line')

    def test_registered_stop_marks_input_with_system_client_on_path(self):
        self.tmux("set-option", "-p", "-t", self.pane, "@agent_state", "working")
        self.fire("Stop")
        self.assertEqual(self.state(), "input")
        self.assertEqual(self.tmux("display-message", "-p", "#{window_bell_flag}"), "1")

    def test_prompt_and_tool_completion_mark_working(self):
        for event in ("UserPromptSubmit", "PreToolUse", "PostToolUse"):
            with self.subTest(event=event):
                self.tmux("set-option", "-p", "-t", self.pane, "@agent_state", "input")
                self.fire(event)
                self.assertEqual(self.state(), "working")

    def test_permission_marks_input(self):
        self.fire("PermissionRequest")
        self.assertEqual(self.state(), "input")
        self.assertEqual(self.tmux("show-options", "-pqv", "-t", self.pane, "@agent_kind"), "codex")

    def test_unattended_and_nested_codex_leave_state_alone(self):
        for key in ("CLAUDE_CODE_SESSION_ATTENDED", "CLAUDECODE"):
            with self.subTest(key=key):
                self.env[key] = "0" if key == "CLAUDE_CODE_SESSION_ATTENDED" else "1"
                self.fire("Stop")
                self.assertEqual(self.state(), "")
                self.env[key] = "1" if key == "CLAUDE_CODE_SESSION_ATTENDED" else ""

    def test_claude_stop_marks_background_while_background_tasks_run(self):
        task = dict(id="b1", type="local_bash", status="running", description="sleep")
        # The window keeps its bell flag, so the case without a bell runs first.
        cases = (("Stop", [task], "background", "0"), ("Stop", [], "input", "1"),
                 ("Notification", [task], "input", "1"))
        for event, tasks, expected, bell in cases:
            with self.subTest(event=event, tasks=len(tasks)):
                self.tmux("set-option", "-p", "-t", self.pane, "@agent_state", "working")
                result = subprocess.run(
                    ["sh", str(self.home / ".claude/hooks/tmux-bell.sh")], env=self.env, text=True,
                    input=json.dumps(dict(hook_event_name=event, background_tasks=tasks)),
                    capture_output=True, timeout=5, check=True)
                self.assertEqual((result.stdout, result.stderr), ("", ""))
                self.assertEqual(self.state(), expected)
                self.assertEqual(self.bell(), bell)

    def test_codex_stop_without_background_terminal_marks_input(self):
        self.start_codex(terminal_seconds=0)
        self.assertEqual(self.wait_for_state("input", 5), "input")
        self.assertEqual(self.watchers(), [])

    def test_codex_stop_marks_background_until_terminal_ends(self):
        self.start_codex(terminal_seconds=2)
        self.assertEqual(self.wait_for_state("background", 5), "background")
        self.assertEqual(self.bell(), "0")
        self.assertEqual(self.wait_for_state("input", 10), "input")
        self.assertEqual(self.bell(), "1")

    def test_codex_watcher_leaves_a_later_state_alone(self):
        self.start_codex(terminal_seconds=1)
        self.assertEqual(self.wait_for_state("background", 5), "background")
        self.assertTrue(self.wait_for(self.watchers, 5))
        self.fire("UserPromptSubmit")
        self.assertTrue(self.wait_for(lambda: not self.watchers(), 10))
        self.assertEqual(self.state(), "working")


if __name__ == "__main__":
    unittest.main()
