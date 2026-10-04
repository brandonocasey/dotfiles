"""Exercise agent configuration scripts with isolated user data."""
import os
from pathlib import Path
import subprocess
import tempfile
import time
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[2]
PRUNE = REPO / "home/dot_claude/hooks/executable_prune-agent-dirs.sh"


class AgentConfigurationTests(unittest.TestCase):
    def test_pruning_preserves_copy_files(self):
        scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="agent-config-test-", dir=scratch) as directory:
            root = Path(directory)
            cache = root / "cache"
            stale = cache / "agents/scratch/old.txt"
            recent = cache / "agents/scratch/recent.txt"
            copy = cache / "agents/copy/unused.md"
            keep = cache / "agents/scratch/.keep"
            for path in (stale, recent, copy, keep):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("preserve unless disposable and expired")
            old = time.time() - 40 * 86400
            for path in (stale, copy, keep):
                os.utime(path, (old, old))
            binary = root / "bin"
            binary.mkdir()
            fake_id = binary / "id"
            fake_id.write_text("#!/bin/sh\nprintf '%s\n' agent-config-test-nonexistent\n")
            fake_id.chmod(0o755)
            # The hook's legacy harness path MUST not resolve to real sessions.
            self.assertFalse(Path("/tmp/claude-agent-config-test-nonexistent").exists())
            env = dict(os.environ, HOME=str(root), XDG_CACHE_HOME=str(cache),
                       XDG_STATE_HOME=str(root / "state"), DAYS="30",
                       PATH=str(binary) + os.pathsep + os.environ["PATH"])
            subprocess.run(["bash", str(PRUNE)], env=env, check=True, timeout=10)
            self.assertFalse(stale.exists())
            self.assertTrue(recent.exists())
            self.assertTrue(keep.exists())
            self.assertTrue(copy.exists(), "Unused copy files must survive age-based pruning")


    def test_codex_visibility_preserves_live_settings(self):
        scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="agent-config-test-", dir=scratch) as directory:
            home = Path(directory) / 'quoted "home" with spaces'
            expected = set()
            for account in ("account-one", "account-two"):
                for name in ("docs", "google-workspace", "skill-creator", "docx"):
                    path = home / ".config/agents/skills/synced" / account / name / "SKILL.md"
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text("fixture")
                    if name != "docx":
                        expected.add(str(path))
            live = ('model = "test-model"\nmodel_reasoning_effort = "medium"\n'
                    '[projects."/example"]\ntrust_level = "trusted"\n'
                    '[hooks.state.example]\nenabled = true\n')
            modifier = REPO / "home/dot_codex/modify_private_config.toml"
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"),
                       XDG_CACHE_HOME=str(home / ".cache"), XDG_STATE_HOME=str(home / ".local/state"))
            def render(value):
                return subprocess.run(["bash", str(modifier)], input=value, text=True,
                                      capture_output=True, env=env, check=True, timeout=10).stdout
            output = render(live)
            config = tomllib.loads(output)
            self.assertEqual(config["model"], "test-model")
            self.assertEqual(config["model_reasoning_effort"], "medium")
            self.assertEqual(config["projects"]["/example"]["trust_level"], "trusted")
            self.assertTrue(config["hooks"]["state"]["example"]["enabled"])
            entries = config["skills"]["config"]
            self.assertEqual({entry["path"] for entry in entries}, expected)
            self.assertTrue(all(entry["enabled"] is False for entry in entries))
            self.assertEqual(render(output), output)

    def test_codex_config_without_synced_skills(self):
        scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="agent-config-test-", dir=scratch) as directory:
            result = subprocess.run(
                ["bash", str(REPO / "home/dot_codex/modify_private_config.toml")],
                input="", text=True, capture_output=True, check=True, timeout=10,
                env=dict(os.environ, HOME=directory, XDG_CONFIG_HOME=directory,
                         XDG_CACHE_HOME=directory, XDG_STATE_HOME=directory))
            self.assertNotIn("skills", tomllib.loads(result.stdout))

if __name__ == "__main__":
    unittest.main()
