"""Check the Codex push guard hook and rules treat mirror pushes like force pushes."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
GUARD = REPO / "home/dot_codex/hooks/executable_guard.py"
RULES = REPO / "home/dot_codex/rules/private_guard.rules"


def scratch_root():
    scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
    scratch.mkdir(parents=True, exist_ok=True)
    return scratch


class CodexGuardTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="codex-guard-", dir=scratch_root())
        self.root = Path(self.directory.name)
        # An empty HOME keeps the user's Git aliases and Codex config out of the checks.
        self.env = dict(os.environ, HOME=str(self.root), XDG_CONFIG_HOME=str(self.root / "config"),
                        CODEX_HOME=str(self.root / "codex"), GIT_CONFIG_NOSYSTEM="1")
        self.env.pop("GIT_CONFIG_GLOBAL", None)

    def tearDown(self):
        self.directory.cleanup()

    def denied(self, command):
        payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": command}})
        result = subprocess.run(["python3", str(GUARD)], input=payload, env=self.env,
                                capture_output=True, text=True, timeout=10, check=True)
        return '"deny"' in result.stdout

    def test_chained_mirror_push_is_denied(self):
        self.assertTrue(self.denied("git fetch origin && git push --mirror backup"))

    def test_lone_mirror_push_is_left_to_the_approval_rule(self):
        self.assertFalse(self.denied("git push --mirror backup"))

    def test_plain_push_is_allowed(self):
        self.assertFalse(self.denied("git fetch origin && git push origin feature"))

    @unittest.skipUnless(shutil.which("codex"), "codex is required")
    def test_rules_prompt_for_mirror_push(self):
        result = subprocess.run(["codex", "execpolicy", "check", "--rules", str(RULES),
                                 "git", "push", "--mirror", "backup"],
                                env=self.env, capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout).get("decision"), "prompt", result.stdout)


if __name__ == "__main__":
    unittest.main()
