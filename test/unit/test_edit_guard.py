"""Check the Edit/Write/MultiEdit PreToolUse guard asks about check changes and passes other edits."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
HOOK = REPO / "home/dot_claude/hooks/executable_edit-guard.py"
SETTINGS = REPO / "home/.chezmoitemplates/claude-settings-modify.sh"

PYPROJECT = '[project]\nname = "x"\n\n[tool.ruff]\nline-length = 100\n\n[tool.other]\nkey = 1\n'


class EditGuardTestCase(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="edit-guard-")
        self.root = Path(self.directory.name)
        self.env = dict(os.environ, HOME=str(self.root / "home"), XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_CACHE_HOME=str(self.root / "cache"), XDG_STATE_HOME=str(self.root / "state"),
                        TMPDIR=str(self.root))

    def tearDown(self):
        self.directory.cleanup()

    def file(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def run_hook(self, tool, tool_input, **fields):
        payload = {"tool_name": tool, "tool_input": tool_input, "cwd": str(self.root), **fields}
        return subprocess.run([sys.executable, "-I", str(HOOK)], env=self.env, capture_output=True, text=True,
                              input=json.dumps(payload), timeout=30)

    def assertAsks(self, tool, tool_input, hint):
        result = self.run_hook(tool, tool_input)
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)["hookSpecificOutput"]
        self.assertEqual(output["hookEventName"], "PreToolUse")
        self.assertEqual(output["permissionDecision"], "ask")
        self.assertNotIn("updatedInput", output)
        self.assertTrue(output["permissionDecisionReason"].startswith(f"edit-guard: this {tool} "))
        self.assertIn(hint, output["permissionDecisionReason"], tool_input)

    def assertPasses(self, tool, tool_input):
        result = self.run_hook(tool, tool_input)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((result.stdout, result.stderr), ("", ""), f"{tool} {tool_input}")


class SuppressionTests(EditGuardTestCase):
    def test_edit_that_adds_a_suppression_asks(self):
        path = self.file("a.py", "import os\nx = f(1)\n")
        for new, hint in (("x = f(1)  # noqa: E501", "# noqa"), ("x = f(1)  # type: ignore[arg-type]", "# type: ignore"),
                          ("x = f(1)  # pylint: disable=unused-import", "# pylint: disable"),
                          ("x = f(1)  # NOQA", "# noqa"), ("x = f(1)  # nosec", "# nosec"),
                          ("x = f(1)  # rubocop:disable Style/X", "# rubocop:disable")):
            with self.subTest(new=new):
                self.assertAsks("Edit", {"file_path": str(path), "old_string": "x = f(1)", "new_string": new}, hint)
        js = self.file("a.ts", "const x = f(1);\n")
        for new, hint in (("// eslint-disable-next-line no-x\nconst x = f(1);", "eslint-disable"),
                          ("/* eslint-disable */\nconst x = f(1);", "eslint-disable"),
                          ("// @ts-ignore\nconst x = f(1);", "@ts-ignore"),
                          ("// @ts-expect-error\nconst x = f(1);", "@ts-expect-error"),
                          ("// nolint\nconst x = f(1);", "// nolint")):
            with self.subTest(new=new):
                self.assertAsks("Edit", {"file_path": str(js), "old_string": "const x = f(1);", "new_string": new}, hint)
        rust = self.file("a.rs", "fn main() {}\n")
        self.assertAsks("Edit", {"file_path": str(rust), "old_string": "fn main", "new_string": "#[allow(dead_code)]\nfn main"},
                        "#[allow(")

    def test_write_with_a_suppression_asks(self):
        self.assertAsks("Write", {"file_path": str(self.root / "new.py"), "content": "x = 1  # noqa\n"}, "# noqa")
        path = self.file("old.py", "x = 1\n")
        self.assertAsks("Write", {"file_path": str(path), "content": "x = 1\ny = 2  # type: ignore\n"}, "# type: ignore")

    def test_multiedit_with_a_suppression_asks(self):
        path = self.file("m.py", "a = 1\nb = 2\n")
        edits = [{"old_string": "a = 1", "new_string": "a = 3"}, {"old_string": "b = 2", "new_string": "b = 2  # noqa"}]
        self.assertAsks("MultiEdit", {"file_path": str(path), "edits": edits}, "# noqa")

    def test_edits_that_keep_or_remove_suppressions_pass(self):
        path = self.file("a.py", "x = f(1)  # noqa: E501\ny = g()  # type: ignore\n")
        self.assertPasses("Edit", {"file_path": str(path), "old_string": "f(1)", "new_string": "f(2)"})
        self.assertPasses("Edit", {"file_path": str(path), "old_string": "  # noqa: E501", "new_string": ""})
        self.assertPasses("Write", {"file_path": str(path), "content": "x = f(1)  # noqa: E501\ny = g(2)  # type: ignore\n"})
        self.assertPasses("MultiEdit", {"file_path": str(path), "edits": [
            {"old_string": "f(1)", "new_string": "f(3)"}, {"old_string": "g()", "new_string": "g(4)"}]})


class ConfigTests(EditGuardTestCase):
    def test_config_files_ask(self):
        for name, text in (("ruff.toml", "line-length = 88\n"), ("sub/tsconfig.json", '{"strict": true}\n'),
                           ("tsconfig.build.json", "{}\n"), ("jest.config.js", "module.exports = {};\n"),
                           (".eslintrc.json", "{}\n"), ("pytest.ini", "[pytest]\n"), ("mypy.ini", "[mypy]\n"),
                           (".golangci.yml", "linters: {}\n"), ("conftest.py", "import pytest\n"),
                           ("vitest.config.ts", "export default {};\n"), (".rubocop.yml", "AllCops: {}\n")):
            path = self.file(name, text)
            with self.subTest(name=name):
                self.assertAsks("Edit", {"file_path": str(path), "old_string": text.splitlines()[0],
                                         "new_string": text.splitlines()[0] + " "}, f"({Path(name).name})")
                self.assertAsks("Write", {"file_path": str(path), "content": text + "\n# more\n"}, f"({Path(name).name})")
                self.assertAsks("MultiEdit", {"file_path": str(path), "edits": [
                    {"old_string": text.splitlines()[0], "new_string": "changed"}]}, "configuration")

    def test_new_config_file_asks(self):
        self.assertAsks("Write", {"file_path": str(self.root / "pkg/.eslintrc.js"), "content": "module.exports = {};\n"},
                        "(.eslintrc.js)")

    def test_unchanged_config_file_passes(self):
        path = self.file("ruff.toml", "line-length = 88\n")
        self.assertPasses("Write", {"file_path": str(path), "content": "line-length = 88\n"})

    def test_tool_sections_of_shared_files_ask(self):
        path = self.file("pyproject.toml", PYPROJECT)
        self.assertAsks("Edit", {"file_path": str(path), "old_string": "line-length = 100",
                                 "new_string": "line-length = 100\nignore = [\"E501\"]"}, "settings in pyproject.toml")
        self.assertAsks("Write", {"file_path": str(path), "content": PYPROJECT + "\n[tool.mypy]\nstrict = false\n"},
                        "settings in pyproject.toml")
        cargo = self.file("Cargo.toml", '[package]\nname = "x"\n\n[lints.rust]\nunsafe_code = "forbid"\n')
        self.assertAsks("Edit", {"file_path": str(cargo), "old_string": '"forbid"', "new_string": '"allow"'},
                        "settings in Cargo.toml")
        cfg = self.file("setup.cfg", "[metadata]\nname = x\n\n[flake8]\nmax-line-length = 100\n")
        self.assertAsks("Edit", {"file_path": str(cfg), "old_string": "100", "new_string": "200"}, "settings in setup.cfg")

    def test_other_sections_of_shared_files_pass(self):
        path = self.file("pyproject.toml", PYPROJECT)
        self.assertPasses("Edit", {"file_path": str(path), "old_string": 'name = "x"', "new_string": 'name = "y"'})
        self.assertPasses("Edit", {"file_path": str(path), "old_string": "key = 1", "new_string": "key = 2"})
        cargo = self.file("Cargo.toml", '[package]\nname = "x"\n\n[lints.rust]\nunsafe_code = "forbid"\n')
        self.assertPasses("Edit", {"file_path": str(cargo), "old_string": 'name = "x"', "new_string": 'name = "y"'})

    def test_package_json_test_and_lint_settings_ask(self):
        path = self.file("package.json", '{\n  "name": "x",\n  "scripts": {\n    "test": "jest",\n    "build": "tsc"\n  }\n}\n')
        self.assertAsks("Edit", {"file_path": str(path), "old_string": '"test": "jest"', "new_string": '"test": "true"'},
                        "package.json")
        self.assertAsks("Edit", {"file_path": str(path), "old_string": '"build": "tsc"',
                                 "new_string": '"build": "tsc",\n    "lint": "echo"'}, "package.json")
        self.assertPasses("Edit", {"file_path": str(path), "old_string": '"build": "tsc"', "new_string": '"build": "vite build"'})
        self.assertPasses("Edit", {"file_path": str(path), "old_string": '"name": "x"', "new_string": '"name": "y"'})


class PassThroughTests(EditGuardTestCase):
    def test_ordinary_edits_pass(self):
        path = self.file("a.py", "def f():\n    return 1\n")
        self.assertPasses("Edit", {"file_path": str(path), "old_string": "return 1", "new_string": "return 2"})
        self.assertPasses("Write", {"file_path": str(self.root / "new.py"), "content": "print('hi')\n"})
        self.assertPasses("MultiEdit", {"file_path": str(path), "edits": [
            {"old_string": "def f", "new_string": "def g"}, {"old_string": "return 1", "new_string": "return 3"}]})
        # A test file edit is not a config change, and a README may mention the words.
        tests = self.file("test_a.py", "def test_a():\n    assert f() == 1\n")
        self.assertPasses("Edit", {"file_path": str(tests), "old_string": "== 1", "new_string": "== 2"})
        readme = self.file("README.md", "Use ruff.\n")
        self.assertPasses("Edit", {"file_path": str(readme), "old_string": "ruff", "new_string": "ruff and mypy"})

    def test_failing_or_other_calls_pass(self):
        path = self.file("a.py", "x = 1\n")
        self.assertPasses("Edit", {"file_path": str(path), "old_string": "missing", "new_string": "y  # noqa"})
        self.assertPasses("Read", {"file_path": str(path)})
        self.assertPasses("Edit", {"old_string": "a", "new_string": "b"})
        self.assertPasses("Edit", {"file_path": str(self.root), "old_string": "a", "new_string": "b # noqa"})

    def test_malformed_input_passes(self):
        for raw in ("{{{", "", "[1]", "null", '{"tool_name": "Edit", "tool_input": "x"}',
                    '{"tool_name": "Edit", "tool_input": {"file_path": "a.py"}, "cwd": 5}'):
            result = subprocess.run([sys.executable, "-I", str(HOOK)], env=self.env, capture_output=True, text=True,
                                    input=raw, timeout=30)
            self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""), raw)

    def test_relative_path_uses_the_session_directory(self):
        self.file("ruff.toml", "a = 1\n")
        self.assertAsks("Edit", {"file_path": "ruff.toml", "old_string": "a = 1", "new_string": "a = 2"}, "(ruff.toml)")


class RegistrationTests(unittest.TestCase):
    def test_hook_runs_on_edit_write_and_multiedit(self):
        settings = json.loads(SETTINGS.read_text().split("cat <<'JSON'\n", 1)[1].split("\nJSON\n", 1)[0])
        groups = [g for g in settings["hooks"]["PreToolUse"]
                  if any("edit-guard.py" in h["command"] for h in g["hooks"])]
        self.assertEqual(len(groups), 1)
        for tool in ("Edit", "Write", "MultiEdit"):
            self.assertTrue(re.fullmatch(groups[0]["matcher"], tool), tool)
        for tool in ("Bash", "Read", "NotebookEdit"):
            self.assertFalse(re.fullmatch(groups[0]["matcher"], tool), tool)
        self.assertIn("python3 -I ~/.claude/hooks/edit-guard.py", [h["command"] for h in groups[0]["hooks"]])


if __name__ == "__main__":
    unittest.main()
