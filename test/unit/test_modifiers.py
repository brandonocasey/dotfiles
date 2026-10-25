"""Check chezmoi modify_ scripts preserve live settings."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
CURSOR = REPO / "home/dot_cursor/modify_cli-config.json"
LINEARMOUSE = REPO / "home/dot_config/linearmouse/modify_linearmouse.json"
OPENCODE = REPO / "home/dot_config/opencode/modify_opencode.jsonc"


def modify(script, live):
    result = subprocess.run(["bash", str(script)], input=live, capture_output=True, text=True,
                            timeout=30, check=True)
    return result.stdout


def managed(script):
    text = script.read_text()
    return json.loads(text.split("\n__MANAGED__\n", 1)[1].split("\n__END__", 1)[0])


class EmbeddedManagedModifierTests(unittest.TestCase):
    def test_equivalent_live_file_passes_through_byte_for_byte(self):
        for script in (CURSOR, LINEARMOUSE):
            with self.subTest(script.name):
                live = json.dumps(managed(script), separators=(",", ":"))
                self.assertEqual(modify(script, live), live)

    def test_program_is_not_a_heredoc_inside_command_substitution(self):
        # macOS /bin/bash 3.2 cannot parse an apostrophe in a heredoc inside $(...).
        for script in (CURSOR, LINEARMOUSE):
            with self.subTest(script.name):
                self.assertNotIn("$(cat <<", script.read_text())

    def test_cursor_keeps_its_own_timestamp(self):
        settings = managed(CURSOR)
        settings["privacyCache"]["updatedAt"] = 42
        live = json.dumps(settings, separators=(",", ":")) + "\n"
        self.assertEqual(modify(CURSOR, live), live)

    def test_changed_managed_key_is_enforced_but_timestamp_kept(self):
        settings = managed(CURSOR)
        settings["privacyCache"]["updatedAt"] = 42
        settings["editor"]["vimMode"] = not settings["editor"]["vimMode"]
        output = json.loads(modify(CURSOR, json.dumps(settings)))
        self.assertEqual(output["editor"], managed(CURSOR)["editor"])
        self.assertEqual(output["privacyCache"]["updatedAt"], 42)


class OpenCodeModifierTests(unittest.TestCase):
    LIVE = {
        "theme": "custom",
        "mcp": {
            "chrome-devtools": {"type": "local", "command": ["old"], "enabled": False, "timeout": 123,
                                "environment": {"FIXTURE": "present"}},
            "other": {"type": "remote", "url": "https://example.invalid"},
        },
    }

    def check(self, output):
        server = output["mcp"]["chrome-devtools"]
        self.assertEqual(server["timeout"], 123)
        self.assertEqual(server["environment"], {"FIXTURE": "present"})
        self.assertTrue(server["enabled"])
        self.assertIn("--headless", server["command"])
        self.assertEqual(output["mcp"]["other"], self.LIVE["mcp"]["other"])
        self.assertEqual(output["theme"], "custom")
        self.assertIn("firefox-devtools", output["mcp"])

    def test_json_keeps_custom_server_settings(self):
        self.check(json.loads(modify(OPENCODE, json.dumps(self.LIVE))))

    def test_jsonc_keeps_custom_server_settings(self):
        live = "// user comment\n" + json.dumps(self.LIVE, indent=2).replace('"present"', '"present",', 1)
        self.check(json.loads(modify(OPENCODE, live)))


class NpmrcModifierTests(unittest.TestCase):
    MANAGED = {"prefix", "cache", "init-version", "init-author-name", "save-exact", "fund"}

    def render(self, live=None):
        """Render npmrc through chezmoi in a fresh home, with XDG data and cache unset."""
        scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="npmrc-test-", dir=scratch) as directory:
            root = Path(directory)
            # Only the npmrc source: the full repository's archive externals download on read.
            source = root / "source/dot_config/npm/modify_npmrc"
            source.parent.mkdir(parents=True)
            source.write_bytes((REPO / "home/dot_config/npm/modify_npmrc").read_bytes())
            home = root / "home"
            target = home / ".config/npm/npmrc"
            target.parent.mkdir(parents=True)
            if live is not None:
                target.write_bytes(live)
            config = root / "chezmoi.toml"
            config.write_text("")
            env = {key: value for key, value in os.environ.items()
                   if key not in ("XDG_CACHE_HOME", "XDG_DATA_HOME")}
            env["HOME"] = str(home)
            output = subprocess.run(
                ["chezmoi", "--source", str(root / "source"), "--config", str(config),
                 "--cache", str(root / "cache"), "--persistent-state", str(root / "state.boltdb"),
                 "-D", str(home), "cat", str(target)],
                env=env, capture_output=True, check=True, timeout=30).stdout
            return output.decode(), str(home)

    def test_keeps_auth_lines_and_writes_absolute_paths(self):
        live = (b"; user comment\r\n"
                b"cache=${XDG_CACHE_HOME}/npm\r\n"
                b"//registry.example/:_authToken=FAKE\r\n"
                b"prefix=${XDG_DATA_HOME}/npm\r\n")
        output, home = self.render(live)
        lines = output.split("\r\n")
        self.assertEqual(lines[:4], ["; user comment", f"cache={home}/.cache/npm",
                                     "//registry.example/:_authToken=FAKE",
                                     f"prefix={home}/.local/share/npm"])
        self.assertNotIn("${", output)
        self.assertEqual(output.count("\n"), output.count("\r\n"))

    def test_fresh_host_gets_every_managed_key(self):
        output, home = self.render()
        lines = output.splitlines()
        self.assertEqual({line.split("=", 1)[0].strip() for line in lines}, self.MANAGED)
        self.assertIn(f"cache={home}/.cache/npm", lines)
        self.assertEqual(output.count("\n"), output.count("\r\n"))


if __name__ == "__main__":
    unittest.main()
