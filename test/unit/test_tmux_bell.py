"""Exercise registered agent status hooks with an isolated tmux server."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
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

    def test_registered_stop_marks_input_with_system_client_on_path(self):
        self.tmux("set-option", "-p", "-t", self.pane, "@agent_state", "working")
        self.fire("Stop")
        self.assertEqual(self.state(), "input")
        self.assertEqual(self.tmux("display-message", "-p", "#{window_bell_flag}"), "1")

    def test_prompt_and_tool_completion_mark_working(self):
        for event in ("UserPromptSubmit", "PostToolUse"):
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


if __name__ == "__main__":
    unittest.main()
