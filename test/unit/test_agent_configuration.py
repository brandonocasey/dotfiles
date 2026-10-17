"""Exercise agent configuration scripts with isolated user data."""
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[2]
CODEX_MODIFIER = REPO / "home/dot_codex/modify_private_config.toml.tmpl"


def render_codex_modifier(directory):
    """Render the Codex modify template into a runnable script."""
    script = Path(directory) / "modify_private_config.toml"
    config = Path(directory) / "chezmoi.toml"
    config.write_text("")
    script.write_text(subprocess.run(
        ["chezmoi", "--source", str(REPO), "--config", str(config), "execute-template"],
        stdin=CODEX_MODIFIER.open(), text=True, capture_output=True,
        check=True, timeout=10).stdout)
    return script


class AgentConfigurationTests(unittest.TestCase):
    def test_codex_visibility_preserves_live_settings(self):
        scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="agent-config-test-", dir=scratch) as directory:
            home = Path(directory) / 'quoted "home" with spaces'
            expected = set()
            for account in ("account-one", "account-two"):
                for name in ("docs", "google-workspace", "skill-creator",
                             "docx", "xlsx", "pptx", "pdf", "unrelated"):
                    path = home / ".config/agents/skills/synced" / account / name / "SKILL.md"
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text("fixture")
                    expected.add(str(path))
            live = ('model = "test-model"\nmodel_reasoning_effort = "medium"\n'
                    '[projects."/example"]\ntrust_level = "trusted"\n'
                    '[hooks.state.example]\nenabled = true\n')
            modifier = render_codex_modifier(directory)
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
                ["bash", str(render_codex_modifier(directory))],
                input="", text=True, capture_output=True, check=True, timeout=10,
                env=dict(os.environ, HOME=directory, XDG_CONFIG_HOME=directory,
                         XDG_CACHE_HOME=directory, XDG_STATE_HOME=directory))
            config = tomllib.loads(result.stdout)
            self.assertEqual(config["skills"]["max_context_tokens"], 1000)
            self.assertNotIn("config", config["skills"])

if __name__ == "__main__":
    unittest.main()
