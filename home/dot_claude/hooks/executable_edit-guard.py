#!/usr/bin/env python3
"""PreToolUse guard for Edit, Write and MultiEdit: ask before a check is weakened.

The user decides (permissionDecision "ask") when an edit
- changes test, lint or type-check configuration: a config file such as ruff.toml,
  tsconfig.json or jest.config.js, or the tool sections of pyproject.toml,
  Cargo.toml, setup.cfg and package.json, or
- adds a lint or type suppression comment: # noqa, # type: ignore,
  eslint-disable, @ts-ignore, #[allow(, and similar.
Every other edit passes with no output. The guard compares the file before and
after the edit, so a line that keeps its existing suppression does not ask.

Exit 0 always; the decision is the JSON on stdout.
"""

import difflib
import json
import os
import re
import sys

MAX_BYTES = 5_000_000

CONFIG_FILE = re.compile(
    r"""^(?:
    pytest\.ini|tox\.ini|\.coveragerc|\.flake8|\.?pylintrc|\.?ruff\.toml|\.?mypy\.ini
    |pyrightconfig\.json|jsconfig\.json|tsconfig(?:\.[\w.-]+)?\.json
    |\.eslintrc(?:\.\w+)?|eslint\.config\.\w+|biome\.jsonc?|\.stylelintrc(?:\.\w+)?|stylelint\.config\.\w+
    |(?:jest|vitest|playwright|cypress|karma|mocha)\.(?:config|conf)\.\w+|vitest\.workspace\.\w+|\.mocharc(?:\.\w+)?
    |\.rubocop(?:_todo)?\.yml|\.golangci\.(?:ya?ml|toml|json)|\.?clippy\.toml|\.shellcheckrc
    |\.yamllint(?:\.ya?ml)?|\.markdownlint(?:-cli2)?(?:\.\w+)?|\.pre-commit-config\.ya?ml|lefthook\.ya?ml
    |phpstan\.neon(?:\.dist)?|phpunit\.xml(?:\.dist)?|psalm\.xml|\.swiftlint\.ya?ml|detekt\.ya?ml
    )$""",
    re.X,
)
# Files that mix tool settings with other data: only a changed line inside a tool section counts.
SECTIONED = {"pyproject.toml", "Cargo.toml", "setup.cfg"}
TOOL_SECTION = re.compile(
    r"^(?:tool\.(?:pytest|ruff|mypy|pylint|pyright|basedpyright|flake8|coverage|bandit|tox)\b"
    r"|(?:workspace\.)?lints\b|tool:pytest|flake8|mypy\b|pylint|coverage:)"
)
SECTION_HEADER = re.compile(r"^\s*\[+\s*([^\]]+?)\s*\]+\s*(?:#.*)?$")
# Top-level package.json keys that hold tool settings, and the names of scripts that run checks.
PACKAGE_TOOL_KEYS = {"jest", "vitest", "mocha", "ava", "nyc", "c8", "eslintConfig", "stylelint", "lint-staged"}
PACKAGE_SCRIPT = re.compile(r"(?:pre|post)?(?:test|lint|typecheck|type-check|check)[:\w.-]*")
# For a package.json that is not valid JSON: a changed line holding one of those keys.
PACKAGE_KEY = re.compile(
    r'"(?:' + "|".join(re.escape(k) for k in sorted(PACKAGE_TOOL_KEYS)) + r"|" + PACKAGE_SCRIPT.pattern + r')"\s*:'
)
# Above this many lines in the changed region (old times new), every line there counts as changed.
MAX_DIFF_CELLS = 1_000_000
SUPPRESSIONS = {
    "# noqa": r"#\s*(?:flake8:\s*|ruff:\s*)?noqa\b",
    "# type: ignore": r"#\s*(?:type|pyright|mypy|pytype):\s*(?:ignore|ignore-errors|basic)\b",
    "# pylint: disable": r"#\s*pylint:\s*(?:disable|skip-file)",
    "# nosec": r"#\s*nosec\b",
    "# rubocop:disable": r"#\s*rubocop:disable\b",
    "# shellcheck disable": r"#\s*shellcheck\s+disable=",
    "eslint-disable": r"\beslint-disable",
    "@ts-ignore": r"@ts-(?:ignore|nocheck)\b",
    "@ts-expect-error": r"@ts-expect-error\b",
    "biome-ignore": r"\bbiome-ignore\b",
    "stylelint-disable": r"\bstylelint-disable",
    "markdownlint-disable": r"\bmarkdownlint-disable",
    "#[allow(": r"#!?\[allow\(",
    "// nolint": r"//\s*nolint\b",
    "swiftlint:disable": r"\bswiftlint:disable\b",
    "@SuppressWarnings": r"@SuppressWarnings\b",
}
SUPPRESSION_RES = {name: re.compile(rx, re.I) for name, rx in SUPPRESSIONS.items()}


def read(path: str) -> str | None:
    """The file's text, "" when it does not exist yet, None when it cannot be read."""
    try:
        if os.path.getsize(path) > MAX_BYTES:
            return None
        with open(path, encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return ""
    except (OSError, UnicodeDecodeError):
        return None


def apply_edits(text: str, edits: list[dict]) -> str | None:
    """text after the edits, or None when one does not apply, so the tool fails on its own."""
    for e in edits:
        old, new = e.get("old_string"), e.get("new_string")
        if not isinstance(old, str) or not isinstance(new, str) or old not in text:
            return None
        text = text.replace(old, new) if e.get("replace_all") else text.replace(old, new, 1)
    return text


def sections(lines: list[str]) -> list[str]:
    """The section header each line sits under, "" before the first."""
    out, current = [], ""
    for line in lines:
        m = SECTION_HEADER.match(line)
        if m:
            current = m.group(1)
        out.append(current)
    return out


def changed_lines(old: str, new: str) -> tuple[list[tuple[str, str]], list[tuple[str, str]]]:
    """The removed and added lines, each with the section it sits in.

    The lines both versions share at the start and the end are skipped before the
    diff, so an edit costs what its own region costs, not the file's length.
    """
    a, b = old.splitlines(), new.splitlines()
    lo = 0
    while lo < min(len(a), len(b)) and a[lo] == b[lo]:
        lo += 1
    hi = 0
    while hi < min(len(a), len(b)) - lo and a[-1 - hi] == b[-1 - hi]:
        hi += 1
    sa, sb = sections(a), sections(b)
    ma, mb = a[lo:len(a) - hi], b[lo:len(b) - hi]
    if len(ma) * len(mb) > MAX_DIFF_CELLS:
        ops = [("replace", 0, len(ma), 0, len(mb))]
    else:
        ops = difflib.SequenceMatcher(None, ma, mb, autojunk=False).get_opcodes()
    removed, added = [], []
    for tag, i1, i2, j1, j2 in ops:
        if tag != "equal":
            removed += list(zip(ma[i1:i2], sa[lo + i1:lo + i2]))
            added += list(zip(mb[j1:j2], sb[lo + j1:lo + j2]))
    return removed, added


def package_settings(text: str) -> dict | None:
    """The tool settings and check scripts in a package.json, None when it is not a JSON object."""
    if not text.strip():
        return {}
    try:
        data = json.loads(text)
    except ValueError:
        return None
    if not isinstance(data, dict):
        return None
    found = {k: v for k, v in data.items() if k in PACKAGE_TOOL_KEYS}
    scripts = data.get("scripts")
    if isinstance(scripts, dict):
        found.update({f"scripts.{k}": v for k, v in scripts.items() if PACKAGE_SCRIPT.fullmatch(k)})
    elif scripts is not None:
        found["scripts"] = scripts
    return found


def reasons(path: str, old: str, new: str) -> list[str]:
    if old == new:
        return []
    name = os.path.basename(path)
    removed, added = changed_lines(old, new)
    found = []
    if CONFIG_FILE.match(name):
        found.append(f"changes test, lint or type-check configuration ({name})")
    elif name in SECTIONED:
        if any(TOOL_SECTION.match(section) for _, section in removed + added):
            found.append(f"changes test, lint or type-check settings in {name}")
    elif name == "package.json":
        before, after = package_settings(old), package_settings(new)
        if before is None or after is None:
            changed = any(PACKAGE_KEY.search(line) for line, _ in removed + added)
        else:
            changed = before != after
        if changed:
            found.append("changes test or lint settings or scripts in package.json")
    for label, rx in SUPPRESSION_RES.items():
        gained = sum(len(rx.findall(line)) for line, _ in added) - sum(len(rx.findall(line)) for line, _ in removed)
        if gained > 0:
            found.append(f"adds a lint or type suppression ({label})")
    return found


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return 0
    if not isinstance(data, dict) or not isinstance(data.get("tool_input") or {}, dict):
        return 0
    tool, tool_input, cwd = data.get("tool_name"), data.get("tool_input") or {}, data.get("cwd") or ""
    path = tool_input.get("file_path")
    if tool not in ("Edit", "Write", "MultiEdit") or not isinstance(path, str) or not isinstance(cwd, str):
        return 0
    path = os.path.join(cwd, os.path.expanduser(path))
    old = read(path)
    if old is None:
        return 0
    if tool == "Write":
        new = tool_input.get("content")
    elif tool == "Edit":
        new = apply_edits(old, [tool_input])
    else:
        new = apply_edits(old, tool_input.get("edits") or [])
    if not isinstance(new, str):
        return 0
    found = reasons(path, old, new)
    if not found:
        return 0
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": f"edit-guard: this {tool} " + " and ".join(found)
        + ". Allow it only if you asked for this change.",
    }}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
