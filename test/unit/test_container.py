"""Check the container entrypoint, Compose file, and docker-run wrapper in isolation."""
import os
from pathlib import Path
import shutil
import socket
import stat
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
ENTRYPOINT = REPO / "docker-entrypoint.sh"
DOCKER_RUN = REPO / "home/private_dot_local/bin/executable_docker-run"


def scratch_root():
    scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
    scratch.mkdir(parents=True, exist_ok=True)
    return scratch


def write_executable(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    path.chmod(0o755)


class EntrypointTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="entrypoint-", dir=scratch_root())
        self.root = Path(self.directory.name)
        self.home = self.root / "home"
        self.state = self.home / "state"
        self.log = self.root / "commands.log"
        bin_dir = self.home / ".local/bin"
        # The entrypoint puts ~/.local/bin first on PATH, so these stubs shadow every
        # privileged, networked, or slow command it would otherwise run.
        write_executable(bin_dir / "sudo", f'#!/bin/sh\necho "sudo $*" >> "{self.log}"\n')
        write_executable(bin_dir / "curl", "#!/bin/sh\nexit 1\n")
        write_executable(bin_dir / "mise", "#!/bin/sh\nexit 0\n")
        write_executable(bin_dir / "claude", "#!/bin/sh\nexit 0\n")
        self.env = dict(os.environ, HOME=str(self.home), STATE_DIR=str(self.state),
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_STATE_HOME=str(self.state / "xdg-state"),
                        XDG_CACHE_HOME=str(self.root / "cache"),
                        ENABLE_SSHD="0", CHROME_BIN="/nonexistent")

    def tearDown(self):
        self.directory.cleanup()

    def run_entrypoint(self, script=ENTRYPOINT):
        return subprocess.run(["bash", str(script), "true"], env=self.env, capture_output=True,
                              text=True, timeout=30, check=True)

    def test_pi_and_gemini_state_persists_in_state_dir(self):
        (self.home / ".pi/agent").mkdir(parents=True)
        (self.home / ".pi/agent/settings.json").write_text("{}\n")
        (self.home / ".gemini").mkdir()
        (self.home / ".gemini/settings.json").write_text("{}\n")
        self.run_entrypoint()
        for name, seeded in (("pi", "agent/settings.json"), ("gemini", "settings.json")):
            link = self.home / f".{name}"
            self.assertTrue(link.is_symlink(), f"~/.{name} should link into the state dir")
            self.assertEqual(link.resolve(), (self.state / name).resolve())
            self.assertTrue((self.state / name / seeded).is_file(), f"{name} config should be seeded")

    def test_docker_socket_mode_is_left_unchanged(self):
        sock_path = self.root / "docker.sock"
        script = self.root / "entrypoint.sh"
        script.write_text(ENTRYPOINT.read_text().replace("/var/run/docker.sock", str(sock_path)))
        server = socket.socket(socket.AF_UNIX)
        self.addCleanup(server.close)
        try:
            server.bind(str(sock_path))
        except OSError as error:
            self.skipTest(f"cannot bind a UNIX socket in scratch: {error}")
        # Unwritable for this user, as a root:docker 0660 host socket is.
        sock_path.chmod(0)
        self.run_entrypoint(script)
        self.assertEqual(stat.S_IMODE(sock_path.stat().st_mode), 0)
        commands = self.log.read_text()
        self.assertNotIn("chmod 666", commands)
        self.assertIn(f"sudo setfacl -m u:{os.getuid()}:rw {sock_path}", commands)


class ComposeTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which("docker"), "docker is required")
    def test_compose_builds_for_amd64(self):
        result = subprocess.run(["docker", "compose", "-f", str(REPO / "docker-compose.yml"),
                                 "config", "--format", "json"],
                                env=dict(os.environ, USER="test", UID="1000", GID="1000"),
                                capture_output=True, text=True, timeout=30)
        if result.returncode and "compose" in result.stderr and "unknown" in result.stderr:
            self.skipTest("docker compose plugin is unavailable")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('"platform": "linux/amd64"', result.stdout)


class DockerRunTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="docker-run-", dir=scratch_root())
        self.root = Path(self.directory.name)
        self.log = self.root / "docker.log"
        write_executable(self.root / "bin/docker", f'#!/bin/sh\nprintf "%s\\n" "$@" > "{self.log}"\n')
        self.env = dict(os.environ, PATH=f"{self.root / 'bin'}:{os.environ['PATH']}")

    def tearDown(self):
        self.directory.cleanup()

    def docker_args(self, **env):
        subprocess.run(["bash", str(DOCKER_RUN), "image", "arg"], env=dict(self.env, **env),
                       cwd=self.root, capture_output=True, text=True, timeout=10, check=True)
        return self.log.read_text().splitlines()

    def test_host_access_is_the_default(self):
        args = self.docker_args()
        for flag in ("--privileged", "--network=host", "--userns=host"):
            self.assertIn(flag, args)
        self.assertEqual(args[-2:], ["image", "arg"])

    def test_host_access_can_be_turned_off(self):
        args = self.docker_args(DOCKER_RUN_PRIVILEGED="0")
        for flag in ("--privileged", "--network=host", "--userns=host"):
            self.assertNotIn(flag, args)
        self.assertIn(f"{self.root}:{self.root}", args)
        self.assertEqual(args[-2:], ["image", "arg"])


if __name__ == "__main__":
    unittest.main()
