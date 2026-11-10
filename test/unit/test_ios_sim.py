"""Check ios-sim keeps one simulator per worktree path, using a fake xcrun that never touches a real simulator."""
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/dot_config/exact_agents/exact_skills/exact_host-preflight/exact_scripts/executable_ios-sim"

# Device list in $FAKE_SIMS (JSON array of name, udid, state), every call logged to $FAKE_SIMS.log. The audio
# helper that `xcrun clang` "builds" logs its arguments to $FAKE_SIMS.audio and exits with $FAKE_ROUTE_STATUS.
FAKE_XCRUN = r"""#!/bin/sh
set -eu
db=$FAKE_SIMS
printf '%s\n' "$*" >>"$db.log"
edit() { jq "$@" "$db" >"$db.new" && mv "$db.new" "$db"; }
if [ "$1" = clang ]; then
  while [ "$#" -gt 0 ]; do [ "$1" != -o ] || out=$2; shift; done
  printf '#!/bin/sh\nprintf "%%s %%s\\n" "$1" "$2" >>"$FAKE_SIMS.audio"\nexit "${FAKE_ROUTE_STATUS:-0}"\n' >"$out"
  chmod +x "$out"
  exit 0
fi
[ "$1" = simctl ] || exit 2
shift
cmd=$1
shift
case $cmd in
  list) jq '{devices: {"fake-runtime": .}}' "$db" ;;
  clone)
    n=$(grep -c '^simctl clone ' "$db.log")
    edit --arg n "$2" --arg u "CLONE-$n" '. + [{name: $n, udid: $u, state: "Shutdown"}]'
    ;;
  boot) edit --arg u "$1" 'map(if .udid == $u then .state = "Booted" else . end)' ;;
  shutdown) edit --arg u "$1" 'map(if .udid == $u then .state = "Shutdown" else . end)' ;;
  rename) edit --arg u "$1" --arg n "$2" 'map(if .udid == $u then .name = $n else . end)' ;;
  delete) edit --arg u "$1" 'map(select(.udid != $u))' ;;
  *) exit 2 ;;
esac
"""


class IosSimTestCase(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="ios-sim-")
        self.root = Path(self.directory.name).resolve()
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        (bin_dir / "xcrun").write_text(FAKE_XCRUN)
        (bin_dir / "xcrun").chmod(0o755)
        self.sims = self.root / "sims.json"
        self.sims.write_text(json.dumps([{"name": "ios-base", "udid": "BASE-UDID", "state": "Shutdown"}]))
        self.markers = self.root / "state/agents/ios-sim/audible"
        self.env = dict(os.environ, HOME=str(self.root / "home"), XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_STATE_HOME=str(self.root / "state"), XDG_CACHE_HOME=str(self.root / "cache"),
                        FAKE_SIMS=str(self.sims), PATH=f"{bin_dir}:{os.environ['PATH']}")
        self.env.pop("IOS_SIM_BASE", None)
        self.repo = self.root / "work/app"
        self.repo.mkdir(parents=True)
        self.git("init", "-q", cwd=self.repo)
        self.git("-c", "user.name=t", "-c", "user.email=t@example.com", "commit", "-q", "--allow-empty", "-m", "init",
                 cwd=self.repo)

    def tearDown(self):
        self.directory.cleanup()

    def git(self, *args, cwd):
        subprocess.run(["git", *args], cwd=cwd, env=self.env, check=True, capture_output=True, text=True)

    def ios_sim(self, *args, cwd=None, **env):
        return subprocess.run(["sh", str(SCRIPT), *args], cwd=cwd or self.repo, env=dict(self.env, **env),
                              capture_output=True, text=True, timeout=60)

    def udid(self, *args, cwd=None):
        result = self.ios_sim(*args, cwd=cwd)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertRegex(result.stdout, r"\A[A-Z0-9-]+\n\Z")
        return result.stdout.strip()

    def devices(self):
        return json.loads(self.sims.read_text())

    def names(self):
        return sorted(device["name"] for device in self.devices() if device["name"] != "ios-base")

    def calls(self, command):
        log = Path(f"{self.sims}.log")
        lines = log.read_text().splitlines() if log.exists() else []
        return [line for line in lines if line.startswith(f"simctl {command} ")]

    def marker_names(self):
        return sorted(p.name for p in self.markers.iterdir()) if self.markers.exists() else []

    def add_device(self, name, udid, state):
        self.sims.write_text(json.dumps(self.devices() + [{"name": name, "udid": udid, "state": state}]))


class BranchChangeTest(IosSimTestCase):
    def test_same_simulator_across_branch_switch_and_detached_head(self):
        first = self.udid()
        for change in (("switch", "-q", "-c", "feature/x"), ("branch", "-q", "-m", "renamed"),
                       ("switch", "-q", "--detach")):
            with self.subTest(change=change):
                self.git(*change, cwd=self.repo)
                self.assertEqual(self.udid(), first)
        self.assertEqual(len(self.calls("clone")), 1)
        self.assertEqual(len(self.names()), 1)
        self.assertRegex(self.names()[0], r"\Awt-app-app-[0-9]+\Z")

    def test_rm_after_branch_switch_deletes_simulator_and_marker(self):
        self.udid()
        self.assertEqual(self.ios_sim("audio", "on").returncode, 0)
        self.assertEqual(len(self.marker_names()), 1)
        self.git("switch", "-q", "-c", "other", cwd=self.repo)
        result = self.ios_sim("rm")
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))
        self.assertEqual(self.names(), [])
        self.assertEqual(self.marker_names(), [])

    def test_rm_leaves_another_worktree_alone(self):
        self.git("worktree", "add", "-q", "-b", "other", str(self.root / "work/second"), cwd=self.repo)
        self.udid()
        kept = self.udid(cwd=self.root / "work/second")
        self.assertEqual(self.ios_sim("rm").returncode, 0)
        self.assertEqual([device["udid"] for device in self.devices() if device["name"] != "ios-base"], [kept])


class WorktreeIdentityTest(IosSimTestCase):
    def test_worktrees_get_different_simulators_even_with_the_same_basename(self):
        (self.root / "other-parent").mkdir()
        self.git("worktree", "add", "-q", "-b", "second", str(self.root / "work/second"), cwd=self.repo)
        self.git("worktree", "add", "-q", "-b", "same-basename", str(self.root / "other-parent/app"), cwd=self.repo)
        udids = [self.udid(cwd=path) for path in (self.repo, self.root / "work/second", self.root / "other-parent/app")]
        self.assertEqual(len(set(udids)), 3)
        self.assertEqual(len(set(self.names())), 3)
        for name in self.names():
            self.assertTrue(name.startswith("wt-app-"), name)

    def test_repeated_call_in_a_subdirectory_finds_the_same_simulator(self):
        first = self.udid()
        (self.repo / "sub").mkdir()
        self.assertEqual(self.udid(cwd=self.repo / "sub"), first)
        self.assertEqual(self.udid(str(self.repo), cwd=self.root), first)


class BranchNamedSimulatorTest(IosSimTestCase):
    def adopt(self, old_name):
        self.add_device(old_name, "OLD-UDID", "Booted")
        self.markers.mkdir(parents=True)
        (self.markers / old_name).touch()
        self.assertEqual(self.udid(), "OLD-UDID")
        self.assertEqual(self.calls("clone"), [])
        self.assertEqual(len(self.names()), 1)
        self.assertRegex(self.names()[0], r"\Awt-app-app-[0-9]+\Z")
        self.assertEqual(self.marker_names(), self.names())
        # The marker kept the simulator audible: a silent route would have run the helper.
        self.assertFalse(Path(f"{self.sims}.audio").exists())

    def test_branch_named_simulator_is_renamed_with_its_marker(self):
        self.git("switch", "-q", "-c", "feature/x", cwd=self.repo)
        self.adopt("wt-app-feature-x")

    def test_detached_head_simulator_named_by_the_directory_is_renamed(self):
        self.git("switch", "-q", "--detach", cwd=self.repo)
        self.adopt("wt-app-app")

    def test_rm_removes_a_branch_named_simulator(self):
        self.add_device("wt-app-main", "OLD-UDID", "Booted")
        self.git("branch", "-q", "-m", "main", cwd=self.repo)
        self.assertEqual(self.ios_sim("rm").returncode, 0)
        self.assertEqual(self.names(), [])

    def test_other_branches_simulator_is_not_adopted(self):
        self.add_device("wt-app-elsewhere", "OLD-UDID", "Shutdown")
        self.assertNotEqual(self.udid(), "OLD-UDID")
        self.assertIn("wt-app-elsewhere", self.names())


class AudioTest(IosSimTestCase):
    def test_audio_on_for_a_booted_simulator_exits_nonzero_when_routing_fails(self):
        self.udid()
        result = self.ios_sim("audio", "on", FAKE_ROUTE_STATUS="1")
        self.assertNotEqual(result.returncode, 0)

    def test_audio_on_routes_a_booted_simulator_to_the_default_output(self):
        udid = self.udid()
        self.assertEqual(self.ios_sim("audio", "on").returncode, 0)
        self.assertEqual(Path(f"{self.sims}.audio").read_text().splitlines()[-1],
                         f"{udid} __sim__hostUseSystemDefaultDeviceUID")
        self.assertTrue(re.fullmatch(r"wt-app-app-[0-9]+", self.marker_names()[0]))


if __name__ == "__main__":
    unittest.main()
