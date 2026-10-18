"""Check fish abbreviations, editor shortcuts, and the Python startup file in isolation."""
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
FISH_DIR = REPO / "home/dot_config/private_fish"
PYTHONRC = REPO / "home/dot_config/python/pythonrc"
FIND_ROOT = REPO / "home/private_dot_local/bin/executable_find-root"


def scratch_root():
    scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
    scratch.mkdir(parents=True, exist_ok=True)
    return scratch


class ShellConfigTestCase(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="shell-config-", dir=scratch_root())
        self.root = Path(self.directory.name)
        self.env = dict(os.environ, HOME=str(self.root / "home"), XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_DATA_HOME=str(self.root / "data"), XDG_CACHE_HOME=str(self.root / "cache"),
                        XDG_STATE_HOME=str(self.root / "state"))

    def tearDown(self):
        self.directory.cleanup()


@unittest.skipUnless(shutil.which("fish"), "fish is required")
class CdrootTests(ShellConfigTestCase):
    def test_cdroot_uses_the_repository_of_the_current_directory(self):
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        # Source files lack the executable bit that chezmoi adds, so wrap them.
        for name in ("find-root", "find-up"):
            wrapper = bin_dir / name
            wrapper.write_text(f'#!/bin/sh\nexec bash "{FIND_ROOT.with_name("executable_" + name)}" "$@"\n')
            wrapper.chmod(0o755)
        repos = [self.root / name for name in ("first repo", "second")]
        for repo in repos:
            subprocess.run(["git", "init", "-q", str(repo)], check=True, env=self.env)
        script = (f"source {FISH_DIR / 'conf.d/abbr.fish'}; cd '{repos[0]}'; _abbr_cdroot; "
                  f"cd '{repos[1]}'; _abbr_cdroot")
        result = subprocess.run(["fish", "--no-config", "-c", script], capture_output=True, text=True,
                                env=dict(self.env, PATH=f"{bin_dir}:{os.environ['PATH']}"), timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        expansions = [shlex.split(line) for line in result.stdout.splitlines()[-2:]]
        self.assertEqual(expansions, [["cd", str(repo)] for repo in repos])


class EditorShortcutTests(unittest.TestCase):
    def test_shortcuts_use_an_installed_picker(self):
        config = (FISH_DIR / "config.fish").read_text()
        lock = (REPO / "home/dot_config/nvim/lazy-lock.json").read_text()
        if "telescope" not in lock:
            self.assertNotIn("Telescope", config)
        self.assertIn("LazyVim.pick('files'", config)
        self.assertIn("LazyVim.pick('live_grep'", config)


class PythonrcTests(ShellConfigTestCase):
    def test_fresh_state_starts_cleanly_and_saves_history(self):
        result = subprocess.run(["python3", "-i"], input="1 + 1\n", capture_output=True, text=True,
                                env=dict(self.env, PYTHONSTARTUP=str(PYTHONRC)), timeout=30)
        self.assertNotIn("Traceback", result.stderr)
        self.assertTrue((self.root / "state/python_history").is_file())


if __name__ == "__main__":
    unittest.main()
