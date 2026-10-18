"""Check npmre workspace discovery, tcpd startup reporting, and git-delete-squashed previews."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
BIN = REPO / "home/private_dot_local/bin"


def scratch_root():
    scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
    scratch.mkdir(parents=True, exist_ok=True)
    return scratch


def write_executable(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    path.chmod(0o755)


class FixtureTestCase(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="workspace-tools-", dir=scratch_root())
        self.root = Path(self.directory.name)
        self.bin = self.root / "bin"
        self.log = self.root / "commands.log"
        self.env = dict(os.environ, HOME=str(self.root / "home"), XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_CACHE_HOME=str(self.root / "cache"), XDG_STATE_HOME=str(self.root / "state"),
                        TMPDIR=str(self.root), GIT_CONFIG_NOSYSTEM="1")
        self.env.pop("GIT_CONFIG_GLOBAL", None)

    def tearDown(self):
        self.directory.cleanup()

    def wrap(self, name):
        """Put a chezmoi source helper on PATH; source files lack the executable bit."""
        write_executable(self.bin / name, f'#!/bin/sh\nexec bash "{BIN / ("executable_" + name)}" "$@"\n')


@unittest.skipUnless(shutil.which("node"), "node is required")
class NpmreTests(FixtureTestCase):
    def setUp(self):
        super().setUp()
        for name in ("find-root", "find-up"):
            self.wrap(name)
        (self.bin / "node").symlink_to(shutil.which("node"))
        write_executable(self.bin / "npm", f'#!/bin/sh\necho "npm $*" >> "{self.log}"\n')
        self.project = self.root / "project"
        for package in ("packages/a", "apps/b"):
            (self.project / package).mkdir(parents=True)
        (self.project / ".git").mkdir()
        # No pnpm on PATH: only the stubs and basic system tools.
        self.env["PATH"] = f"{self.bin}:/usr/bin:/bin"

    def listed(self, *args):
        result = subprocess.run(["bash", str(BIN / "executable_npmre"), "--list", *args], cwd=self.project,
                                env=self.env, capture_output=True, text=True, timeout=30)
        return result, sorted(result.stdout.split())

    def test_npm_workspaces_object_lists_packages(self):
        (self.project / "package.json").write_text(json.dumps({"workspaces": {"packages": ["packages/*"]}}))
        result, dirs = self.listed()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(dirs, [".", "packages/a"])

    def test_quoted_pnpm_globs_list_packages(self):
        (self.project / "pnpm-workspace.yaml").write_text(
            "packages:\n  - 'packages/*'\n  - \"apps/*\"  # apps\n  - '!**/test/**'\ncatalog:\n  x: 1\n")
        result, dirs = self.listed("--pnpm")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(dirs, [".", "apps/b", "packages/a"])

    def test_list_does_not_install_pnpm(self):
        (self.project / "pnpm-workspace.yaml").write_text("packages:\n  - packages/*\n")
        result, _ = self.listed("--pnpm")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.log.exists(), self.log.read_text() if self.log.exists() else "")

    def test_unreadable_workspaces_fail(self):
        (self.project / "package.json").write_text("{ not json")
        result, _ = self.listed()
        self.assertNotEqual(result.returncode, 0)


class TcpdTests(FixtureTestCase):
    def setUp(self):
        super().setUp()
        # sudo runs its command as this user; pkill stops the stub capture by its PID file.
        write_executable(self.bin / "sudo", '#!/bin/sh\n[ "$1" = -v ] && exit 0\nexec "$@"\n')
        write_executable(self.bin / "pkill", f'#!/bin/sh\nkill "$(cat "{self.root}/tcpdump.pid")"\n')
        self.env["PATH"] = f"{self.bin}:{os.environ['PATH']}"

    def run_tcpd(self):
        return subprocess.run(["bash", str(BIN / "executable_tcpd")], input="\n", env=self.env,
                              capture_output=True, text=True, timeout=30)

    def test_failed_start_is_reported(self):
        write_executable(self.bin / "tcpdump", '#!/bin/sh\necho "tcpdump: any: no such device" >&2\nexit 1\n')
        result = self.run_tcpd()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no such device", result.stdout + result.stderr)
        self.assertNotIn(".pcap", result.stdout)

    def test_capture_path_is_printed_after_stop(self):
        write_executable(self.bin / "tcpdump", f'#!/bin/sh\necho $$ > "{self.root}/tcpdump.pid"\n'
                         'while [ "$1" != -w ]; do shift; done\n: > "$2"\nexec sleep 30\n')
        result = self.run_tcpd()
        self.assertEqual(result.returncode, 0, result.stderr)
        path = result.stdout.strip().splitlines()[-1]
        self.assertTrue(path.endswith(".pcap") and Path(path).is_file(), result.stdout)


class GitDeleteSquashedTests(FixtureTestCase):
    def git(self, *args, cwd=None):
        return subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@example.invalid",
                               "-c", "commit.gpgsign=false", *args], cwd=cwd or self.work, env=self.env,
                              capture_output=True, text=True, timeout=30, check=True).stdout.strip()

    def setUp(self):
        super().setUp()
        self.work = self.root / "work"
        self.git("init", "-q", "-b", "main", str(self.work), cwd=self.root)
        (self.work / "f").write_text("base\n")
        self.git("add", "f")
        self.git("commit", "-qm", "base")
        self.git("checkout", "-qb", "squashed")
        (self.work / "f").write_text("change\n")
        self.git("commit", "-qam", "change")
        self.git("checkout", "-q", "main")
        self.git("merge", "--squash", "-q", "squashed")
        self.git("commit", "-qm", "squash")
        self.git("checkout", "-qb", "current")
        (self.work / "g").write_text("wip\n")
        self.git("add", "g")
        self.git("commit", "-qm", "wip")
        self.git("init", "-q", "--bare", str(self.root / "origin.git"), cwd=self.root)
        self.git("remote", "add", "origin", str(self.root / "origin.git"))
        self.git("push", "-q", "origin", "main")
        self.git("remote", "set-head", "origin", "main")

    def run_helper(self, *args):
        return subprocess.run(["bash", str(BIN / "executable_git-delete-squashed"), *args], cwd=self.work,
                              env=self.env, capture_output=True, text=True, timeout=30)

    def test_preview_stays_on_the_current_branch(self):
        result = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("squashed", result.stdout.split())
        self.assertEqual(self.git("branch", "--show-current"), "current")
        self.assertTrue((self.work / "g").is_file())
        self.assertIn("squashed", self.git("branch", "--list", "squashed"))

    def test_delete_removes_squashed_branches(self):
        result = self.run_helper("--delete")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git("branch", "--list", "squashed"), "")
        self.assertIn("current", self.git("branch", "--list", "current"))


if __name__ == "__main__":
    unittest.main()
