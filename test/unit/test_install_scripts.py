"""Check the chezmoi install scripts and Git credential config with stubbed commands."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPTS = REPO / "home/.chezmoiscripts/any-linux"
INSTALLERS = ("run_onchange_after_05-claude-install.sh", "run_onchange_after_05-codex-install.sh",
              "run_onchange_after_05-cursor-install.sh")


def scratch_root():
    scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
    scratch.mkdir(parents=True, exist_ok=True)
    return scratch


def write_executable(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    path.chmod(0o755)


class ScriptTestCase(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="install-scripts-", dir=scratch_root())
        self.root = Path(self.directory.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "commands.log"
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_STATE_HOME=str(self.root / "state"), XDG_CACHE_HOME=str(self.root / "cache"),
                        RUNNING_IN_DOCKER="", PATH=f"{self.bin}:{os.environ['PATH']}")

    def tearDown(self):
        self.directory.cleanup()

    def stub(self, name, body='echo "{name} $*" >> "{log}"'):
        write_executable(self.bin / name, "#!/bin/sh\n" + body.format(name=name, log=self.log) + "\n")

    def run_script(self, script, env=None):
        return subprocess.run(["bash", str(script)], env=env or self.env, capture_output=True,
                              text=True, timeout=30)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []


class InstallerTests(ScriptTestCase):
    def test_failed_download_fails_the_script(self):
        self.stub("curl", "exit 22")
        self.stub("uname", "echo Linux")
        for name in INSTALLERS:
            with self.subTest(name):
                self.assertNotEqual(self.run_script(SCRIPTS / name).returncode, 0)

    def test_failed_installer_fails_the_script(self):
        self.stub("curl", "echo 'exit 3'")
        self.stub("uname", "echo Linux")
        for name in INSTALLERS:
            with self.subTest(name):
                self.assertNotEqual(self.run_script(SCRIPTS / name).returncode, 0)

    def test_successful_installer_succeeds(self):
        self.stub("curl", "echo 'echo \"installer $*\" >> \"{log}\"'")
        self.stub("uname", "echo Linux")
        for name in INSTALLERS:
            with self.subTest(name):
                self.assertEqual(self.run_script(SCRIPTS / name).returncode, 0)
        self.assertIn("installer 2.1.296", self.calls())


class BootstrapTests(ScriptTestCase):
    def run_bootstrap(self, manager):
        # A PATH of stubs only, so the host's own package manager is never found.
        for tool in ("bash", "sh", "cat", "dirname"):
            os.symlink(shutil.which(tool), self.bin / tool)
        self.stub("uname", "echo Linux")
        self.stub("brew")
        self.stub(manager)
        env = dict(self.env, PATH=str(self.bin))
        result = self.run_script(SCRIPTS / "run_onchange_before_00-bootstrap.sh", env)
        self.assertEqual(result.returncode, 0, result.stderr)
        return [call for call in self.calls() if call.startswith(manager)]

    def test_apt_installs_debian_packages(self):
        calls = self.run_bootstrap("apt-get")
        self.assertIn("build-essential", calls[-1])

    def test_pacman_uses_arch_packages_and_noconfirm(self):
        call = self.run_bootstrap("pacman")[-1].split()
        self.assertIn("--noconfirm", call)
        self.assertIn("base-devel", call)
        self.assertNotIn("build-essential", call)

    def test_dnf_installs_development_tools(self):
        call = self.run_bootstrap("dnf")[-1].split()
        self.assertIn("@development-tools", call)
        self.assertNotIn("build-essential", call)


class FisherTests(ScriptTestCase):
    def test_existing_fisher_still_syncs_plugins(self):
        functions = self.home / ".config/fish/functions"
        functions.mkdir(parents=True)
        (functions / "fisher.fish").write_text("function fisher; end\n")
        self.stub("fish")
        result = self.run_script(SCRIPTS / "run_onchange_after_10-fisher-update.sh.tmpl")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("fish -c fisher update", self.calls())


class LoginShellTests(ScriptTestCase):
    def run_login_shell(self, current_shell, registered):
        self.stub("fish")
        fish = str(self.bin / "fish")
        shells = self.root / "shells"
        shells.write_text("/bin/sh\n" + (fish + "\n" if registered else ""))
        script = self.root / "login-shell.sh"
        script.write_text((SCRIPTS / "run_onchange_after_01-login-shell.sh").read_text()
                          .replace("/etc/shells", str(shells)))
        self.stub("sudo")
        self.stub("whoami", "echo tester")
        self.stub("getent", f'echo "tester:x:1000:1000::/home/tester:{current_shell}"')
        result = self.run_script(script)
        self.assertEqual(result.returncode, 0, result.stderr)
        return fish, self.calls()

    def test_registered_fish_is_still_selected(self):
        fish, calls = self.run_login_shell("/bin/bash", registered=True)
        self.assertIn(f"sudo chsh -s {fish} tester", calls)
        self.assertFalse([call for call in calls if call.startswith("sudo tee")])

    def test_unregistered_fish_is_registered_and_selected(self):
        fish, calls = self.run_login_shell("/bin/bash", registered=False)
        self.assertIn("sudo tee -a " + str(self.root / "shells"), calls)
        self.assertIn(f"sudo chsh -s {fish} tester", calls)

    def test_current_fish_login_shell_is_left_alone(self):
        fish, calls = self.run_login_shell(str(self.bin / "fish"), registered=True)
        self.assertEqual(calls, [])


class GitCredentialTests(ScriptTestCase):
    def test_github_helper_uses_gh_from_path(self):
        config = self.home / ".config/git/config"
        config.parent.mkdir(parents=True)
        shutil.copyfile(REPO / "home/dot_config/git/config", config)
        self.stub("gh", 'echo "gh $*" >> "{log}"; printf "username=stub\\npassword=from-path\\n"')
        env = dict(self.env, GIT_TERMINAL_PROMPT="0", GIT_CONFIG_NOSYSTEM="1", GH_CONFIG_DIR=str(self.root / "gh"))
        for name in ("GH_TOKEN", "GITHUB_TOKEN", "GIT_CONFIG_GLOBAL"):
            env.pop(name, None)
        result = subprocess.run(["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n",
                                env=env, cwd=self.root, capture_output=True, text=True, timeout=30)
        self.assertIn("password=from-path", result.stdout, result.stderr)
        self.assertIn("gh auth git-credential get", self.calls())


if __name__ == "__main__":
    unittest.main()
