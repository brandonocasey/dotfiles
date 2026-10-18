"""Check the Brewfile cleanup and settings backup scripts against isolated fixtures."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile

REPO = Path(__file__).resolve().parents[2]
BREW_CLEANUP = REPO / "home/.chezmoiscripts/any-linux/run_onchange_after_00-brew-cleanup.sh.tmpl"
BACKUP = REPO / "backup-settings.sh"

# Stands in for brew: `bundle list` reads `brew '<name>'`/`cask '<name>'` lines,
# installed packages come from installed.txt, and every call is logged.
FAKE_BREW = """#!/bin/sh
root="$(dirname "$0")/.."
echo "$*" >> "$root/brew.log"
case "$1 $2" in
  "bundle list")
    kind="$3"; file="${4#--file=}"
    [ "$kind" = --formula ] && word=brew || word=cask
    sed -n "s/^ *$word '\\([^']*\\)'.*/\\1/p" "$file" ;;
  "bundle cleanup") echo "would remove unrelated" ;;
  "list --formula"|"list --cask") grep -qx "$3" "$root/installed.txt" ;;
  "uses --installed") grep -x "$3" "$root/needed.txt" 2>/dev/null || true ;;
esac
"""


def scratch_root():
    scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
    scratch.mkdir(parents=True, exist_ok=True)
    return scratch


def write_executable(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    path.chmod(0o755)


class BrewCleanupTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="brew-cleanup-", dir=scratch_root())
        self.root = Path(self.directory.name)
        self.source = self.root / "source"
        brew_dir = self.source / ".chezmoiscripts/.brew"
        brew_dir.mkdir(parents=True)
        shutil.copyfile(REPO / "home/.chezmoiscripts/.brew/brew-env.sh", brew_dir / "brew-env.sh")
        (brew_dir / "mac.Brewfile").write_text("if OS.mac?\n  cask 'mac-app'\nend\n")
        self.cli = brew_dir / "cli.Brewfile"
        write_executable(self.root / "bin/brew", FAKE_BREW)
        (self.root / "installed.txt").write_text("kept\ndropped\nunrelated\n")
        self.env = dict(os.environ, HOME=str(self.root / "home"), CHEZMOI_SOURCE_DIR=str(self.source),
                        XDG_STATE_HOME=str(self.root / "state"),
                        PATH=f"{self.root / 'bin'}:{os.environ['PATH']}")

    def tearDown(self):
        self.directory.cleanup()

    def apply(self, *formulae):
        self.cli.write_text("".join(f"brew '{name}'\n" for name in formulae))
        subprocess.run(["bash", str(BREW_CLEANUP)], env=self.env, capture_output=True, text=True,
                       timeout=30, check=True)
        log = self.root / "brew.log"
        calls = log.read_text().splitlines() if log.exists() else []
        log.unlink(missing_ok=True)
        return calls

    def test_first_run_records_packages_without_removing_any(self):
        calls = self.apply("kept", "dropped")
        self.assertFalse([call for call in calls if call.startswith(("uninstall", "bundle cleanup"))])

    def test_only_packages_dropped_from_a_brewfile_are_removed(self):
        self.apply("kept", "dropped")
        calls = self.apply("kept")
        self.assertIn("uninstall --formula dropped", calls)
        self.assertFalse([call for call in calls if "unrelated" in call or "bundle cleanup" in call])
        # Once removed from the record, a package is not uninstalled again.
        calls = self.apply("kept")
        self.assertFalse([call for call in calls if call.startswith("uninstall")])


    def test_package_other_packages_need_is_kept_and_retried(self):
        self.apply("kept", "dropped")
        (self.root / "needed.txt").write_text("dropped\n")
        calls = self.apply("kept")
        self.assertFalse([call for call in calls if call.startswith("uninstall")])
        (self.root / "needed.txt").unlink()
        self.assertIn("uninstall --formula dropped", self.apply("kept", "other"))


class BackupSettingsTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="backup-settings-", dir=scratch_root())
        self.root = Path(self.directory.name)
        self.home = self.root / "home"
        self.tmp = self.root / "tmp"
        self.tmp.mkdir()
        project = self.home / "Projects/app"
        (project / "node_modules/dep").mkdir(parents=True)
        (project / "node_modules/dep/index.js").write_text("module.exports = 1\n")
        (project / "src.js").write_text("console.log(1)\n")
        (self.home / ".ssh").mkdir()
        (self.home / ".ssh/config").write_text("Host fixture\n")
        (self.home / "Downloads").mkdir()
        self.bin = self.root / "bin"
        # A trash stub records any attempt to trash project files.
        write_executable(self.bin / "trash", f'#!/bin/sh\necho "$*" >> "{self.root}/trash.log"\n')
        self.env = dict(os.environ, HOME=str(self.home), TMPDIR=str(self.tmp),
                        PATH=f"{self.bin}:{os.environ['PATH']}")

    def tearDown(self):
        self.directory.cleanup()

    def run_backup(self):
        return subprocess.run(["bash", str(BACKUP)], env=self.env, cwd=self.home,
                              capture_output=True, text=True, timeout=60)

    @unittest.skipUnless(shutil.which("rsync") and shutil.which("zip"), "rsync and zip are required")
    def test_backup_leaves_projects_untouched_and_skips_node_modules(self):
        result = self.run_backup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.home / "Projects/app/node_modules/dep/index.js").is_file())
        self.assertFalse((self.root / "trash.log").exists())
        archives = list((self.home / "Downloads").glob("*.zip"))
        self.assertEqual(len(archives), 1)
        names = zipfile.ZipFile(archives[0]).namelist()
        self.assertTrue(any(name.endswith("Projects/app/src.js") for name in names), names)
        self.assertFalse([name for name in names if "node_modules" in name])
        self.assertEqual(list(self.tmp.iterdir()), [], "staging should be removed after success")

    @unittest.skipUnless(shutil.which("rsync"), "rsync is required")
    def test_failed_archive_fails_and_keeps_staging(self):
        write_executable(self.bin / "zip", "#!/bin/sh\nexit 12\n")
        result = self.run_backup()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Created zip file", result.stdout)
        staged = list(self.tmp.iterdir())
        self.assertEqual(len(staged), 1, "staging should be kept after a failure")
        self.assertIn(str(staged[0]), result.stderr)
        self.assertTrue((staged[0] / "Projects/app/src.js").is_file())


if __name__ == "__main__":
    unittest.main()
