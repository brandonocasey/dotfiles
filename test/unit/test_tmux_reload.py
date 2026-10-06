"""Check chezmoi reloads existing tmux servers without starting new ones."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = Path(".chezmoiscripts/any-linux/run_onchange_after_30-tmux-reload.sh.tmpl")
TMUX = next((str(path) for path in (
    Path("/opt/homebrew/bin/tmux"),
    Path("/home/linuxbrew/.linuxbrew/bin/tmux"),
    Path("/usr/local/bin/tmux"),
) if path.is_file()), shutil.which("tmux"))
CHEZMOI = shutil.which("chezmoi")


@unittest.skipUnless(TMUX and CHEZMOI, "tmux and chezmoi are required")
class TmuxReloadTests(unittest.TestCase):
    def setUp(self):
        scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
        scratch.mkdir(parents=True, exist_ok=True)
        self.directory = tempfile.TemporaryDirectory(prefix="tmux-reload-", dir=scratch)
        self.root = Path(self.directory.name)
        self.home = self.root / "home with spaces"
        self.source = self.root / "source"
        for path in (self.home, self.source, self.root / "sockets"):
            path.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), TMUX="", TMUX_PANE="",
                        TMUX_TMPDIR=str(self.root / "sockets"),
                        XDG_CACHE_HOME=str(self.root / "cache"),
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_STATE_HOME=str(self.root / "state"))
        self.config = self.source / "dot_config/tmux/tmux.conf"
        self.config.parent.mkdir(parents=True)
        self.config.write_text("set -g @reload-test first\n")
        if (REPO / "home" / SCRIPT).exists():
            target = self.source / SCRIPT
            target.parent.mkdir(parents=True)
            shutil.copyfile(REPO / "home" / SCRIPT, target)
        self.chezmoi = [CHEZMOI, "--config", str(self.root / "chezmoi.toml"),
                        "--source", str(self.source), "--destination", str(self.home),
                        "--persistent-state", str(self.root / "chezmoi-state.boltdb")]

    def tearDown(self):
        self.run_command([TMUX, "kill-server"], check=False)
        self.directory.cleanup()

    def run_command(self, args, check=True):
        return subprocess.run(args, env=self.env, capture_output=True, text=True,
                              timeout=15, check=check)

    def test_running_server_reloads_only_after_config_changes(self):
        self.run_command([TMUX, "-f", "/dev/null", "new-session", "-d", "-s", "test", "sleep 120"])
        self.run_command(self.chezmoi + ["apply"])
        self.assertEqual(self.run_command([TMUX, "show-option", "-gv", "@reload-test"]).stdout.strip(), "first")
        self.run_command([TMUX, "set", "-g", "@reload-test", "manual"])
        self.run_command(self.chezmoi + ["apply"])
        self.assertEqual(self.run_command([TMUX, "show-option", "-gv", "@reload-test"]).stdout.strip(), "manual")
        self.config.write_text("set -g @reload-test second\n")
        self.run_command(self.chezmoi + ["apply"])
        self.assertEqual(self.run_command([TMUX, "show-option", "-gv", "@reload-test"]).stdout.strip(), "second")

    def test_apply_without_server_does_not_start_one(self):
        self.run_command(self.chezmoi + ["apply"])
        self.assertNotEqual(self.run_command([TMUX, "list-sessions"], check=False).returncode, 0)


if __name__ == "__main__":
    unittest.main()
