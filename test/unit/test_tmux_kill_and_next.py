import os
from pathlib import Path
import pty
import select
import subprocess
import tempfile
import time
import unittest

from test_tmux_reload import TMUX


REPO = Path(__file__).resolve().parents[2]


@unittest.skipUnless(TMUX, "tmux is required")
class TmuxKillAndNextTests(unittest.TestCase):
    def setUp(self):
        scratch = REPO / ".cache/agents/scratch/tmux-kill-and-next"
        scratch.mkdir(parents=True, exist_ok=True)
        self.root = Path(tempfile.mkdtemp(dir=scratch))
        self.socket = self.root / "socket"
        self.env = dict(os.environ, HOME=str(self.root), TERM="xterm-256color",
                        XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_CACHE_HOME=str(self.root / "cache"),
                        XDG_STATE_HOME=str(self.root / "state"),
                        TMUX="", TMUX_PANE="",
                        PATH=str(Path(TMUX).parent) + os.pathsep + os.defpath)
        self.run_tmux("-f", "/dev/null", "new-session", "-d", "-s", "survivor")
        config = (REPO / "home/dot_config/tmux/tmux.conf").read_text()
        binding = "\n".join(line for line in config.splitlines()
                            if "kill-and-next=" in line or
                            line.startswith(("bind-key K ", "bind-key k ")))
        self.run_tmux("source-file", "-", input=binding)

    def tearDown(self):
        self.run_tmux("kill-server", check=False)

    def run_tmux(self, *args, **kwargs):
        return subprocess.run([TMUX, "-S", str(self.socket), *args],
                              env=self.env, capture_output=True, text=True,
                              timeout=5, check=kwargs.pop("check", True), **kwargs)

    def press_binding(self, target, key):
        master, slave = pty.openpty()
        client = subprocess.Popen([TMUX, "-S", str(self.socket), "attach-session", "-t", target],
                                  env=self.env, stdin=slave, stdout=slave, stderr=slave)
        os.close(slave)
        try:
            deadline = time.monotonic() + 3
            while not self.run_tmux("list-clients").stdout.strip():
                if client.poll() is not None or time.monotonic() >= deadline:
                    self.fail("tmux client did not attach")
                time.sleep(0.01)
            os.write(master, b"\x02" + key.encode())
            output = bytearray()
            deadline = time.monotonic() + 1
            while time.monotonic() < deadline:
                if select.select([master], [], [], 0.02)[0]:
                    output.extend(os.read(master, 65536))
                if self.run_tmux("has-session", "-t", target, check=False).returncode:
                    break
            return output.decode(errors="replace")
        finally:
            client.terminate()
            client.wait(timeout=5)
            os.close(master)

    def test_kills_only_current_session_with_shell_characters(self):
        for key, name in (
            ("K", '40910 Fix "whats new" popup on production'),
            ("k", "plain session"),
            ("K", "Unicode 雪 'quoted' $HOME `true` $(true) ; #"),
        ):
            with self.subTest(key=key, name=name):
                target = self.run_tmux("new-session", "-d", "-P", "-F", "#{session_id}",
                                       "-s", name).stdout.strip()
                screen = self.press_binding(target, key)
                sessions = self.run_tmux("list-sessions", "-F", "#{session_name}").stdout.splitlines()
                self.assertEqual(sessions, ["survivor"], screen)


if __name__ == "__main__":
    unittest.main()
