"""Check code-shape reports functions a change adds or makes worse past the code-quality.md limits."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from textwrap import dedent
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "home/private_dot_local/bin/executable_code-shape"
SETTINGS = REPO / "home/.chezmoitemplates/claude-settings-modify.sh"


def nested_python(depth, name="nested"):
    """Python source for a function whose innermost statement sits in `depth` if blocks."""
    lines = [f"def {name}(x):"]
    lines += ["    " * (level + 1) + f"if x > {level}:" for level in range(depth)]
    lines += ["    " * (depth + 1) + "x -= 1", "    return x"]
    return "\n".join(lines) + "\n"


def flat_branches(branches, language):
    """Source for a function with `branches` unnested ifs: its cognitive complexity is `branches`."""
    if language == "py":
        body = "".join(f"    if x == {n}:\n        x += 1\n" for n in range(branches))
        return f"def branchy(x):\n{body}    return x\n"
    body = "".join(f"    if (x == {n}) {{\n        x += 1;\n    }}\n" for n in range(branches))
    return f"int branchy(int x) {{\n{body}    return x;\n}}\n"


HELPER = "\n\ndef helper(x):\n    return x + 1\n"
# legacy nests 5 deep, with cognitive complexity 1 + 2 + 3 + 4 + 5 = 15.
LEGACY = nested_python(5, "legacy") + HELPER
DEEPER = nested_python(6, "legacy") + HELPER
SHALLOWER = nested_python(4, "legacy") + HELPER
DEEPER_BREAKS = [
    "legacy.py:1: legacy: nesting depth 6 > 3 (was 5)",
    "legacy.py:1: legacy: cognitive complexity 21 > 15 (was 15)",
]
RUST_RECEIVER_AND_FOUR = (
    "impl Thing {\n"
    "    fn method(&self, a: u8, b: (u8, u8), c: impl Fn(u8, u8) -> u8, d: [u8; 4]) -> u8 {\n"
    "        a\n"
    "    }\n"
    "}\n"
)
RUST_FIVE = "fn five(a: u8, b: (u8, u8), c: u8, d: u8, e: u8) -> u8 {\n    a\n}\n"
JS_NESTED_4 = "function nested(x) {\n  if (x > 0) {\n    if (x > 1) {\n      if (x > 2) {\n        if (x > 3) {\n" \
              "          x -= 1;\n        }\n      }\n    }\n  }\n  return x;\n}\n"
DEEP_CALLBACK = dedent("""\
    items.forEach(function (x) {
      if (x > 0) {
        if (x > 1) {
          if (x > 2) {
            if (x > 3) {
              x -= 1;
            }
          }
        }
      }
    });
    """)
# Each layout below nests 4 deep, except the Kotlin `else ->` arm, which nests 3.
NESTING_LAYOUTS = {
    "switch.c": dedent("""\
        int pick(int x) {
            switch (x) {
            case 1:
                if (x > 0) {
                    if (x > 1) {
                        if (x > 2) {
                            x -= 1;
                        }
                    }
                }
                break;
            default:
                break;
            }
            return x;
        }
        """),
    "condition.js": dedent("""\
        function wrapped(a, b) {
          if (a) {
            if (b) {
              if (
                a > 1 &&
                b > 1
              ) {
                if (a > b) {
                  a -= 1;
                }
              }
            }
          }
          return a;
        }
        """),
    "value.rs": dedent("""\
        fn total(items: &[u8]) -> u8 {
            let mut sum = 0;
            for item in items {
                let step = match item {
                    0 => 0,
                    n => {
                        if *n > 1 {
                            if *n > 2 {
                                sum += 1;
                            }
                        }
                        1
                    }
                };
                sum += step;
            }
            sum
        }
        """),
    "arms.kt": dedent("""\
        fun label(x: Int): String {
            return when (x) {
                1 -> "one"
                else -> {
                    if (x > 1) {
                        if (x > 2) {
                            "many"
                        } else {
                            "two"
                        }
                    } else {
                        "none"
                    }
                }
            }
        }
        """),
    "allman.cpp": dedent("""\
        int allman(int x)
        {
            for (int i = 0; i < x; ++i)
            {
                if (i > 0)
                {
                    if (i > 1)
                    {
                        if (i > 2)
                        {
                            x -= 1;
                        }
                    }
                }
            }
            return x;
        }
        """),
    "comment.py": dedent("""\
        def commented(x):
            if x > 0:
                if x > 1:
        # a comment at column 0
                    if x > 2:
                        if x > 3:
                            x -= 1
            return x
        """),
    "guarded.py": dedent("""\
        def guarded(x):
            try:
                if x > 0:
                    if x > 1:
                        if x > 2:
                            x -= 1
            except ValueError:
                pass
            return x
        """),
}


class CodeShapeTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        uv = shutil.which("uv")
        if uv is None:
            raise AssertionError("code-shape runs under uv; put uv on PATH to run these tests")
        cls.uv = uv
        # Run offline against the real uv cache and Python installs, so a temporary
        # HOME downloads nothing.
        cls.uv_env = {
            "UV_CACHE_DIR": cls.uv_output("cache", "dir"),
            "UV_PYTHON_INSTALL_DIR": cls.uv_output("python", "dir"),
            "UV_OFFLINE": "1",
        }
        warm = subprocess.run([uv, "run", "--quiet", "--script", str(SCRIPT), "--help"],
                              env=dict(os.environ, **cls.uv_env), capture_output=True, text=True)
        if warm.returncode != 0:
            raise AssertionError(f"lizard is not in the uv cache; run `uv run --script {SCRIPT} --help` "
                                 f"once with network access.\n{warm.stderr}")

    @classmethod
    def uv_output(cls, *args):
        return subprocess.run([cls.uv, *args], capture_output=True, text=True, check=True).stdout.strip()

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="code-shape-")
        root = Path(self.directory.name)
        self.repo = root / "repo"
        self.repo.mkdir()
        self.env = dict(os.environ, HOME=str(root / "home"), XDG_CONFIG_HOME=str(root / "config"),
                        XDG_CACHE_HOME=str(root / "cache"), XDG_STATE_HOME=str(root / "state"),
                        TMPDIR=str(root), GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1",
                        GIT_AUTHOR_NAME="Test", GIT_AUTHOR_EMAIL="test@example.com",
                        GIT_COMMITTER_NAME="Test", GIT_COMMITTER_EMAIL="test@example.com", **self.uv_env)
        self.git("init", "-q", "-b", "main")
        self.write("README.md", "test\n")
        self.commit("base")

    def tearDown(self):
        self.directory.cleanup()

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.repo, env=self.env, check=True, capture_output=True,
                              text=True).stdout

    def write(self, name, text):
        (self.repo / name).write_text(text)

    def commit(self, message):
        self.git("add", "-A")
        self.git("commit", "-q", "-m", message)

    def code_shape(self, *args, stdin=None, cwd=None):
        return subprocess.run([self.uv, "run", "--quiet", "--script", str(SCRIPT), *args], cwd=cwd or self.repo,
                              env=self.env, input=stdin, capture_output=True, text=True, timeout=120)


class CheckTests(CodeShapeTestCase):
    def test_new_functions_past_a_limit_are_reported(self):
        files = {
            "nest3.py": nested_python(3),
            "nest4.py": nested_python(4),
            "cog15.py": flat_branches(15, "py"),
            "cog16.py": flat_branches(16, "py"),
            "cog25.cpp": flat_branches(25, "cpp"),
            "cog26.cpp": flat_branches(26, "cpp"),
            "four.py": "def four(a, b, c, d):\n    return a\n",
            "five.py": "def five(a, b, c, d, e):\n    return a\n",
            "receiver.py": "class Thing:\n    def method(self, a, b, c, d):\n        return a\n",
            "receiver.rs": RUST_RECEIVER_AND_FOUR,
            "five.rs": RUST_FIVE,
            "generic.rs": "fn pair<T: Fn(u8, u8) -> u8>(a: T, b: (u8, u8), c: u8, d: u8) -> u8 {\n    c\n}\n",
            "init.swift": "struct Point {\n    init?(a: (Int, Int), b: Int, c: Int, d: Int) {\n"
                          "        return nil\n    }\n}\n",
            "join.kt": 'fun join(sep: String = ", ", a: Int, b: Int, c: Int): String {\n    return sep\n}\n',
            "notes.md": nested_python(4),
            "pytool": "#!/usr/bin/env python3\n" + nested_python(4),
            "uvtool": "#!/usr/bin/env -S uv run --script\n" + nested_python(4),
            "jstool": "#!/usr/bin/env node\n" + JS_NESTED_4,
            "notes": nested_python(4),
        }
        for name, text in files.items():
            self.write(name, text)
        result = self.code_shape("check", "--base", "HEAD")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(sorted(result.stdout.splitlines()), sorted([
            "nest4.py:1: nested: nesting depth 4 > 3 (new function)",
            "cog16.py:1: branchy: cognitive complexity 16 > 15 (new function)",
            "cog26.cpp:1: branchy: cognitive complexity 26 > 25 (new function)",
            "five.py:1: five: parameters 5 > 4 (new function)",
            "five.rs:1: five: parameters 5 > 4 (new function)",
            "pytool:2: nested: nesting depth 4 > 3 (new function)",
            "uvtool:2: nested: nesting depth 4 > 3 (new function)",
            "jstool:2: nested: nesting depth 4 > 3 (new function)",
        ]))

    def test_nesting_follows_each_language_layout(self):
        for name, text in NESTING_LAYOUTS.items():
            self.write(name, text)
        result = self.code_shape("check", "--base", "HEAD")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(sorted(result.stdout.splitlines()), sorted([
            "switch.c:1: pick: nesting depth 4 > 3 (new function)",
            "condition.js:1: wrapped: nesting depth 4 > 3 (new function)",
            "value.rs:1: total: nesting depth 4 > 3 (new function)",
            "allman.cpp:1: allman: nesting depth 4 > 3 (new function)",
            "comment.py:1: commented: nesting depth 4 > 3 (new function)",
            "guarded.py:1: guarded: nesting depth 4 > 3 (new function)",
        ]))

    def test_unchanged_functions_with_shared_names_are_skipped(self):
        callbacks = "items.forEach(function (x) {\n  return x;\n});\n" + DEEP_CALLBACK
        self.write("callbacks.js", callbacks)
        self.commit("callbacks")
        self.write("callbacks.js", "items.map(function (x) {\n  return x * 2;\n});\n" + callbacks)
        result = self.code_shape("check", "--base", "HEAD")
        self.assertEqual((result.returncode, result.stdout), (0, ""), result.stderr)

    def test_symlinks_and_submodules_are_skipped(self):
        self.write("legacy.py", LEGACY)
        self.commit("legacy")
        os.symlink("legacy.py", self.repo / "tracked-link.py")
        self.git("add", "tracked-link.py")
        os.symlink("legacy.py", self.repo / "untracked-link.py")
        (self.repo / "submodule").mkdir()
        self.git("update-index", "--add", "--cacheinfo", f"160000,{self.git('rev-parse', 'HEAD').strip()},submodule")
        result = self.code_shape("check", "--base", "HEAD")
        self.assertEqual((result.returncode, result.stdout), (0, ""), result.stderr)

    def test_only_new_or_worse_breaks_are_reported(self):
        self.write("legacy.py", LEGACY)
        self.commit("legacy")
        cases = [
            ("another function edited", "legacy.py", LEGACY.replace("x + 1", "x + 2"), []),
            ("same depth", "legacy.py", LEGACY.replace("x -= 1", "x -= 2"), []),
            ("shallower but still over", "legacy.py", SHALLOWER, []),
            ("deeper", "legacy.py", DEEPER, DEEPER_BREAKS),
            ("renamed", "moved.py", LEGACY.replace("x + 1", "x + 2"), []),
        ]
        for name, path, text, expected in cases:
            with self.subTest(name):
                if path != "legacy.py":
                    self.git("mv", "legacy.py", path)
                self.write(path, text)
                result = self.code_shape("check", "--base", "HEAD")
                self.assertEqual((result.returncode, result.stdout.splitlines()),
                                 (1 if expected else 0, expected), result.stderr)
                self.git("reset", "-q", "--hard")

    def test_head_revision_is_read_from_git(self):
        self.write("legacy.py", LEGACY)
        self.commit("legacy")
        self.write("legacy.py", DEEPER)
        self.commit("deeper")
        self.write("legacy.py", LEGACY)
        result = self.code_shape("check", "--base", "HEAD~1", "--head", "HEAD")
        self.assertEqual((result.returncode, result.stdout.splitlines()), (1, DEEPER_BREAKS), result.stderr)

    def test_unknown_base_is_an_error(self):
        result = self.code_shape("check", "--base", "no-such-revision")
        self.assertEqual(result.returncode, 2)
        self.assertIn("no-such-revision", result.stderr)


class HookTests(CodeShapeTestCase):
    def run_hook(self, tool, file_path, response):
        event = {"session_id": "s", "transcript_path": "", "cwd": str(self.repo), "hook_event_name": "PostToolUse",
                 "tool_name": tool, "tool_input": {"file_path": file_path}, "tool_response": response,
                 "tool_use_id": "t"}
        return self.code_shape("hook", stdin=json.dumps(event), cwd=self.repo.parent)

    def test_reports_breaks_the_edit_added_or_worsened(self):
        worse = [f"{self.repo}/{line}" for line in DEEPER_BREAKS]
        cases = [
            ("Edit that worsens", "Edit", "legacy.py", DEEPER, {"originalFile": LEGACY}, worse),
            ("Edit that keeps the depth", "Edit", "legacy.py", LEGACY.replace("x -= 1", "x -= 2"),
             {"originalFile": LEGACY}, []),
            ("Write that creates, relative path", "Write", "new.py", nested_python(4),
             {"type": "create", "originalFile": None},
             [f"{self.repo}/new.py:1: nested: nesting depth 4 > 3 (new function)"]),
            ("Write that updates", "Write", "legacy.py", DEEPER, {"type": "update", "originalFile": LEGACY}, worse),
            ("unchecked file type", "Write", "notes.md", nested_python(4), {"type": "create", "originalFile": None},
             []),
        ]
        for name, tool, path, text, response, expected in cases:
            with self.subTest(name):
                self.write(path, text)
                file_path = path if "relative" in name else str(self.repo / path)
                result = self.run_hook(tool, file_path, {"filePath": str(self.repo / path), **response})
                self.assertEqual(result.returncode, 0, result.stderr)
                if not expected:
                    self.assertEqual(result.stdout, "")
                    continue
                reply = json.loads(result.stdout)
                self.assertEqual(reply["decision"], "block")
                self.assertEqual(reply["reason"].splitlines()[-len(expected):], expected)

    def test_missing_original_text_is_an_error(self):
        self.write("legacy.py", LEGACY)
        result = self.run_hook("Edit", str(self.repo / "legacy.py"), {"filePath": str(self.repo / "legacy.py")})
        self.assertEqual(result.returncode, 1)
        self.assertRegex(result.stderr, r"^code-shape: .*originalFile")


class RegistrationTests(unittest.TestCase):
    def test_hook_runs_after_edit_write_and_multiedit(self):
        settings = json.loads(SETTINGS.read_text().split("cat <<'JSON'\n", 1)[1].split("\nJSON\n", 1)[0])
        groups = [g for g in settings["hooks"]["PostToolUse"]
                  if any("code-shape" in h["command"] for h in g["hooks"])]
        self.assertEqual(len(groups), 1)
        for tool in ("Edit", "Write", "MultiEdit"):
            self.assertTrue(re.fullmatch(groups[0]["matcher"], tool), tool)
        for tool in ("Bash", "Read", "NotebookEdit"):
            self.assertFalse(re.fullmatch(groups[0]["matcher"], tool), tool)
        self.assertEqual([h["command"] for h in groups[0]["hooks"]], ["~/.local/bin/code-shape hook"])


if __name__ == "__main__":
    unittest.main()
