"""Check chezmoi modify_ scripts preserve live settings."""
import json
from pathlib import Path
import subprocess
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


if __name__ == "__main__":
    unittest.main()
