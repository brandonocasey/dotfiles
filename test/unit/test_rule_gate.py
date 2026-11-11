"""Check the rule-gate hook denies edits whose rules may be missing from context, until the rules are read whole or a
denied edit is retried."""
import contextlib
import fcntl
import importlib.util
import itertools
import json
import os
from pathlib import Path
import re
import resource
import subprocess
import sys
import tempfile
import threading
import time
import unittest

REPO = Path(__file__).resolve().parents[2]
HOOK = REPO / "home/dot_claude/hooks/executable_rule-gate.py"
SETTINGS = REPO / "home/.chezmoitemplates/claude-settings-modify.sh"

REASON = ("rule-gate: the rules for {file} may not be in your context yet: {rules}. Retry this edit, changed if those "
          "rules require it. The text of each rule follows, unless an earlier denial in this conversation showed it. "
          "Read any rule whose full text you cannot see.")
RULE_TEXT = "\n\n----- ~/.claude/rules/{name} -----\n{text}"


class RuleGateTestCase(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="rule-gate-")
        self.root = Path(self.directory.name).resolve()
        self.home, self.work, self.outside = self.root / "home", self.root / "work", self.root / "outside"
        self.state = self.root / "state/agents/rule-gate"
        for path in (self.home / ".claude/rules", self.work, self.outside, self.root / "tmp"):
            path.mkdir(parents=True)
        env = {k: v for k, v in os.environ.items() if k != "CLAUDE_PROJECT_DIR"}
        self.env = dict(env, HOME=str(self.home), XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_CACHE_HOME=str(self.root / "cache"), XDG_STATE_HOME=str(self.root / "state"),
                        TMPDIR=str(self.root / "tmp"))
        self.sessions = (f"session-{n}" for n in itertools.count())
        self.session = next(self.sessions)

    def tearDown(self):
        self.directory.cleanup()

    def rule(self, name, globs, directory=None):
        path = (directory or self.home / ".claude/rules") / name
        path.parent.mkdir(parents=True, exist_ok=True)
        listed = "".join(f'  - "{g}"\n' for g in globs)
        path.write_text(f"---\npaths:\n{listed}---\n\n# {name}\n")
        return path

    def run_hook(self, payload, env=None, raw=None):
        return subprocess.run([sys.executable, "-I", str(HOOK)], env=env or self.env, capture_output=True, text=True,
                              input=json.dumps(payload) if raw is None else raw, timeout=30)

    def event(self, **fields):
        return {"session_id": self.session, "cwd": str(self.work), **fields}

    def edit(self, file, tool="Edit", cwd=None, env=None, **fields):
        tool_input = {"file_path": str(file)} if tool != "MultiEdit" else {"file_path": str(file), "edits": []}
        return self.run_hook(self.event(hook_event_name="PreToolUse", tool_name=tool, tool_input=tool_input,
                                        **({"cwd": str(cwd)} if cwd else {}), **fields), env=env)

    def loaded(self, reason, file_path=None, **fields):
        result = self.run_hook(self.event(hook_event_name="InstructionsLoaded", load_reason=reason,
                                          **({"file_path": str(file_path)} if file_path else {}), **fields))
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))

    def pre_compact(self, **fields):
        self.assertPasses(self.run_hook(self.event(hook_event_name="PreCompact", **fields)))

    def batch_done(self, *calls, **fields):
        self.assertPasses(self.run_hook(self.event(hook_event_name="PostToolBatch", tool_calls=list(calls), **fields)))

    def numbered(self, text, first=1):
        """The text as a Read result shows it: each line after its number and a tab."""
        return "\n".join(f"{n}\t{line}" for n, line in enumerate(text.split("\n"), first))

    def read(self, file, shown=None, tool="Read"):
        """A finished call that read the file, by default returning its whole text as the Read tool does."""
        if shown is None:
            shown = self.numbered(Path(file).read_text())
        return {"tool_name": tool, "tool_input": {"file_path": str(file)}, "tool_use_id": "toolu_01",
                "tool_response": shown}

    def assertDenied(self, result, file, rules, texts=None):
        """Check the deny and its message; `texts` lists each (name, text) the message carries."""
        self.assertEqual((result.returncode, result.stderr), (0, ""))
        output = json.loads(result.stdout)["hookSpecificOutput"]
        self.assertEqual(output["hookEventName"], "PreToolUse")
        self.assertEqual(output["permissionDecision"], "deny")
        reason = output["permissionDecisionReason"]
        expected = REASON.format(file=file, rules=rules)
        if texts is None:
            self.assertEqual(reason.partition("\n\n----- ")[0], expected)
        else:
            self.assertEqual(reason, expected + "".join(RULE_TEXT.format(name=n, text=t) for n, t in texts))

    def assertPasses(self, result, context=""):
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""), context)

    def assertHookFailed(self, result, message):
        self.assertEqual((result.returncode, result.stdout), (1, ""), result.stderr)
        self.assertRegex(result.stderr, rf"\Arule-gate failed: {message}\n\Z")

    def state_files(self):
        return sorted(p.name for p in self.state.iterdir()) if self.state.exists() else []


class FirstEditTests(RuleGateTestCase):
    def test_recorded_rule_passes_inside_the_working_folder(self):
        rule = self.rule("py.md", ["**/*.py"])
        self.loaded("path_glob_match", rule)
        self.assertPasses(self.edit(self.work / "src/a.py"))

    def test_first_edit_in_the_working_folder_is_denied_and_the_retry_passes(self):
        self.rule("py.md", ["**/*.py"])
        file = self.work / "src/a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")
        self.batch_done()
        self.assertPasses(self.edit(file))
        self.assertPasses(self.edit(self.work / "other.py"))
        lines = (self.state / self.session).read_text().splitlines()
        self.assertEqual(lines, [f"main {(self.home / '.claude/rules/py.md').resolve()}"])

    def test_first_edit_outside_the_working_folder_is_denied_once(self):
        self.rule("py.md", ["**/*.py"])
        file = self.outside / "pkg/a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")
        self.batch_done()
        self.assertPasses(self.edit(file))

    def test_new_file_in_a_missing_directory_is_gated(self):
        self.rule("py.md", ["pkg/new/*.py"])
        file = self.work / "pkg/new/a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")

    def test_relative_file_path_uses_the_session_directory(self):
        self.rule("py.md", ["src/*.py"])
        self.assertDenied(self.edit("src/a.py"), "src/a.py", "~/.claude/rules/py.md")

    def test_non_matching_file_passes(self):
        self.rule("py.md", ["**/*.py"])
        self.assertPasses(self.edit(self.work / "a.txt"))
        self.assertPasses(self.edit(self.outside / "a.txt"))
        self.assertEqual(self.state_files(), [])

    def test_write_and_multiedit_behave_like_edit(self):
        self.rule("py.md", ["**/*.py"])
        for tool in ("Write", "MultiEdit"):
            with self.subTest(tool=tool):
                self.session = next(self.sessions)
                file = self.work / "a.py"
                self.assertDenied(self.edit(file, tool), file, "~/.claude/rules/py.md")
                self.batch_done()
                self.assertPasses(self.edit(file, tool))

    def test_other_tools_pass_without_a_record(self):
        self.rule("py.md", ["**/*.py"])
        for tool in ("Read", "Bash", "NotebookEdit"):
            with self.subTest(tool=tool):
                self.assertPasses(self.edit(self.work / "a.py", tool))
        self.assertEqual(self.state_files(), [])

    def test_rules_are_listed_with_and_and_a_serial_comma(self):
        self.rule("a-one.md", ["**/*.py"])
        self.rule("b-two.md", ["**/*.py"])
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/a-one.md and ~/.claude/rules/b-two.md")
        self.batch_done()
        self.rule("c-three.md", ["**/*.py"])
        self.assertDenied(self.edit(file), file, "~/.claude/rules/c-three.md")
        self.session = next(self.sessions)
        self.assertDenied(self.edit(file), file, "~/.claude/rules/a-one.md, ~/.claude/rules/b-two.md, "
                          "and ~/.claude/rules/c-three.md")

    def test_only_unrecorded_rules_are_named(self):
        known = self.rule("a-known.md", ["**/*.py"])
        self.rule("b-new.md", ["**/*.py"])
        self.loaded("path_glob_match", known)
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/b-new.md")


class AgentTests(RuleGateTestCase):
    def test_a_sub_agent_is_denied_once_on_its_own(self):
        rule = self.rule("py.md", ["**/*.py"])
        self.loaded("path_glob_match", rule)
        file = self.work / "a.py"
        self.assertPasses(self.edit(file))
        self.assertDenied(self.edit(file, agent_id="agent-1", agent_type="Explore"), file, "~/.claude/rules/py.md")
        self.batch_done(agent_id="agent-1", agent_type="Explore")
        self.assertPasses(self.edit(file, agent_id="agent-1", agent_type="Explore"))
        self.assertDenied(self.edit(file, agent_id="agent-2"), file, "~/.claude/rules/py.md")

    def test_a_sub_agents_record_does_not_cover_main(self):
        rule = self.rule("py.md", ["**/*.py"])
        self.loaded("path_glob_match", rule, agent_id="agent-1")
        file = self.work / "a.py"
        self.assertPasses(self.edit(file, agent_id="agent-1"))
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")

    def test_a_rule_loaded_before_the_late_compact_reload_stays_recorded(self):
        rule = self.rule("py.md", ["**/*.py"])
        file = self.work / "a.py"
        self.pre_compact()
        self.loaded("path_glob_match", rule)
        self.loaded("compact", self.work / "CLAUDE.md")
        self.assertPasses(self.edit(file))

    def test_pre_compact_clears_only_that_agents_records(self):
        rule = self.rule("py.md", ["**/*.py"])
        file = self.work / "a.py"
        for fields in ({}, {"agent_id": "agent-1"}, {"agent_id": "agent-2"}):
            self.loaded("path_glob_match", rule, **fields)
        self.pre_compact(agent_id="agent-1", agent_type="Explore")
        self.assertDenied(self.edit(file, agent_id="agent-1"), file, "~/.claude/rules/py.md")
        self.batch_done(agent_id="agent-1")
        self.assertPasses(self.edit(file))
        self.assertPasses(self.edit(file, agent_id="agent-2"))
        self.pre_compact()
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")
        self.assertPasses(self.edit(file, agent_id="agent-2"))
        self.assertPasses(self.edit(file, agent_id="agent-1"))

    def test_pre_compact_without_a_valid_session_or_agent_changes_nothing(self):
        for fields in ({"session_id": "../evil"}, {"agent_id": "a b"}, {"session_id": None}):
            self.pre_compact(**fields)
        self.assertEqual(self.state_files(), [])

    def test_other_load_reasons_change_nothing(self):
        rule = self.rule("py.md", ["**/*.py"])
        reasons = ("session_start", "nested_traversal", "include", "compact")
        for reason in reasons:
            self.loaded(reason, rule)
        self.assertEqual(self.state_files(), [])
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")
        self.batch_done()
        for reason in reasons:
            self.loaded(reason, rule)
        self.assertPasses(self.edit(file))

    def test_hook_waits_for_the_state_file_lock(self):
        self.rule("py.md", ["**/*.py"])
        self.state.mkdir(parents=True)
        payload = self.event(hook_event_name="PreToolUse", tool_name="Edit",
                             tool_input={"file_path": str(self.work / "a.py")})
        with open(self.state / self.session, "a+") as locked:
            fcntl.flock(locked, fcntl.LOCK_EX)
            with subprocess.Popen([sys.executable, "-I", str(HOOK)], env=self.env, stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE, text=True) as proc:
                assert proc.stdin is not None and proc.stdout is not None
                try:
                    proc.stdin.write(json.dumps(payload))
                    proc.stdin.close()
                    time.sleep(1)
                    self.assertIsNone(proc.poll(), "the hook did not wait for the lock")
                finally:
                    fcntl.flock(locked, fcntl.LOCK_UN)
                self.assertIn("permissionDecision", proc.stdout.read())
                self.assertEqual(proc.wait(timeout=10), 0)

    def test_hooks_waiting_on_a_replaced_state_file_keep_each_others_records(self):
        self.rule("py.md", ["**/*.py"])
        self.state.mkdir(parents=True)
        files = [self.work / f"{n}.py" for n in range(6)]
        with contextlib.ExitStack() as stack, open(self.state / self.session, "a+") as locked:
            fcntl.flock(locked, fcntl.LOCK_EX)
            procs = []
            for file in files:
                payload = self.event(hook_event_name="PreToolUse", tool_name="Edit",
                                     tool_input={"file_path": str(file)})
                proc = subprocess.Popen([sys.executable, "-I", str(HOOK)], env=self.env, stdin=subprocess.PIPE,
                                        stdout=subprocess.DEVNULL, text=True)
                stack.enter_context(proc)
                assert proc.stdin is not None
                proc.stdin.write(json.dumps(payload))
                proc.stdin.close()
                procs.append(proc)
            time.sleep(1)
            fcntl.flock(locked, fcntl.LOCK_UN)
            self.assertEqual([proc.wait(timeout=10) for proc in procs], [0] * len(files))
        self.assertEqual(len((self.state / self.session).read_text().splitlines()), len(files))


class RetryTests(RuleGateTestCase):
    def test_each_file_is_denied_until_a_denied_edit_is_retried(self):
        rule = self.rule("py.md", ["**/*.py"])
        first, second, third = (self.work / f"{name}.py" for name in ("a", "b", "c"))
        self.assertDenied(self.edit(first), first, "~/.claude/rules/py.md")
        self.assertDenied(self.edit(second), second, "~/.claude/rules/py.md")
        self.batch_done()
        self.assertDenied(self.edit(third), third, "~/.claude/rules/py.md")
        self.assertPasses(self.edit(second))
        self.assertPasses(self.edit(first))
        self.assertPasses(self.edit(self.work / "d.py"))
        self.assertEqual((self.state / self.session).read_text().splitlines(), [f"main {rule.resolve()}"])

    def test_every_edit_of_a_denied_file_in_the_same_batch_is_denied(self):
        self.rule("py.md", ["**/*.py"])
        first, second = self.work / "a.py", self.work / "b.py"
        self.assertDenied(self.edit(first), first, "~/.claude/rules/py.md")
        self.assertDenied(self.edit(first), first, "~/.claude/rules/py.md")
        self.assertDenied(self.edit(second), second, "~/.claude/rules/py.md")
        self.assertDenied(self.edit(first), first, "~/.claude/rules/py.md")
        self.batch_done()
        self.assertPasses(self.edit(first))
        self.assertPasses(self.edit(self.work / "c.py"))

    def test_a_batch_end_without_denied_edits_writes_nothing(self):
        self.batch_done()
        self.batch_done(agent_id="agent-1")
        self.assertEqual(self.state_files(), [])

    def test_edits_sent_together_are_each_denied(self):
        self.rule("py.md", ["**/*.py"])
        files = [self.work / f"{n}.py" for n in range(4)]
        with contextlib.ExitStack() as stack:
            procs = [stack.enter_context(subprocess.Popen(
                [sys.executable, "-I", str(HOOK)], env=self.env, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE, text=True)) for _ in files]
            for proc, file in zip(procs, files):
                assert proc.stdin is not None
                proc.stdin.write(json.dumps(self.event(hook_event_name="PreToolUse", tool_name="Edit",
                                                       tool_input={"file_path": str(file)})))
                proc.stdin.close()
            for proc, file in zip(procs, files):
                assert proc.stdout is not None and proc.stderr is not None
                returncode = proc.wait(timeout=30)
                result = subprocess.CompletedProcess(proc.args, returncode, proc.stdout.read(), proc.stderr.read())
                self.assertDenied(result, file, "~/.claude/rules/py.md")

    def test_a_rule_load_drops_denied_edits(self):
        rule = self.rule("py.md", ["**/*.py"])
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")
        self.loaded("path_glob_match", rule)
        self.assertPasses(self.edit(self.work / "b.py"))
        self.assertEqual((self.state / self.session).read_text().splitlines(), [f"main {rule.resolve()}"])

    def test_a_compaction_forgets_denied_edits(self):
        self.rule("py.md", ["**/*.py"])
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")
        self.batch_done()
        self.pre_compact()
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")
        self.batch_done()
        self.assertPasses(self.edit(file))

    def test_denied_edits_belong_to_one_agent(self):
        self.rule("py.md", ["**/*.py"])
        file, other = self.work / "a.py", self.work / "b.py"
        self.assertDenied(self.edit(file, agent_id="agent-10"), file, "~/.claude/rules/py.md")
        self.assertDenied(self.edit(file, agent_id="agent-1"), file, "~/.claude/rules/py.md")
        self.batch_done(agent_id="agent-1")
        self.assertPasses(self.edit(file, agent_id="agent-1"))
        self.assertDenied(self.edit(file, agent_id="agent-10"), file, "~/.claude/rules/py.md")
        self.assertDenied(self.edit(other, agent_id="agent-10"), other, "~/.claude/rules/py.md")
        self.pre_compact(agent_id="agent-1")
        self.assertDenied(self.edit(other), other, "~/.claude/rules/py.md")
        self.batch_done(agent_id="agent-10")
        self.assertPasses(self.edit(file, agent_id="agent-10"))

    def test_two_names_for_one_rule_are_both_listed(self):
        real = self.rule("real.md", ["**/*.py"])
        (self.home / ".claude/rules/alias.md").symlink_to(real)
        file, other = self.work / "a.py", self.work / "b.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/alias.md and ~/.claude/rules/real.md")
        self.assertDenied(self.edit(other), other, "~/.claude/rules/alias.md and ~/.claude/rules/real.md")
        self.batch_done()
        self.assertPasses(self.edit(file))
        self.assertEqual((self.state / self.session).read_text().splitlines(), [f"main {real.resolve()}"])

    def test_a_rule_name_with_a_carriage_return_is_read_on_retry(self):
        self.rule("cr\rname.md", ["**/*.py"])
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/cr\rname.md")
        self.batch_done()
        self.assertPasses(self.edit(file))
        self.assertPasses(self.edit(self.work / "b.py"))


class DenialTextTests(RuleGateTestCase):
    def test_the_first_denial_for_a_rule_carries_its_whole_text(self):
        first = self.rule("a-one.md", ["**/*.py"])
        second = self.rule("b-two.md", ["**/*.py"])
        long_text = second.read_text() + "- Küß the cook; keep `{braces}`.\n" + "x" * 30_000 + "\nlast line\n"
        second.write_text(long_text, encoding="utf-8")
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/a-one.md and ~/.claude/rules/b-two.md",
                          texts=[("a-one.md", first.read_text()), ("b-two.md", long_text)])

    def test_later_denials_for_a_rule_leave_its_text_out_until_a_compaction(self):
        rule = self.rule("py.md", ["**/*.py"])
        text = [("py.md", rule.read_text())]
        first, second, third = (self.work / f"{name}.py" for name in ("a", "b", "c"))
        self.assertDenied(self.edit(first), first, "~/.claude/rules/py.md", texts=text)
        self.assertDenied(self.edit(first), first, "~/.claude/rules/py.md", texts=[])
        self.assertDenied(self.edit(second), second, "~/.claude/rules/py.md", texts=[])
        self.assertDenied(self.edit(second, agent_id="agent-10"), second, "~/.claude/rules/py.md", texts=text)
        self.assertDenied(self.edit(second, agent_id="agent-1"), second, "~/.claude/rules/py.md", texts=text)
        self.batch_done()
        self.assertDenied(self.edit(third), third, "~/.claude/rules/py.md", texts=[])
        self.pre_compact()
        self.assertDenied(self.edit(third), third, "~/.claude/rules/py.md", texts=text)

    def test_two_names_for_one_rule_carry_its_text_once(self):
        real = self.rule("real.md", ["**/*.py"])
        (self.home / ".claude/rules/alias.md").symlink_to(real)
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/alias.md and ~/.claude/rules/real.md",
                          texts=[("alias.md", real.read_text())])


class RuleReadTests(RuleGateTestCase):
    UNCHANGED = ("File unchanged since last read. The content from the earlier Read tool_result in this conversation "
                 "is still current — refer to that instead of re-reading.")

    def test_a_rule_read_whole_lets_the_first_edit_pass(self):
        rule = self.rule("sub dir/py;1.md", ["**/*.py"])
        text = rule.read_text()
        whole = self.numbered(text)
        (self.root / "profile").mkdir()
        (self.root / "profile/rules").symlink_to(self.home / ".claude/rules")
        arrows = "\n".join(f"{n:>6}→{line}" for n, line in enumerate(text.split("\n"), 1))
        cases = {
            "absolute path": [self.read(rule)],
            "path under ~": [self.read("~/.claude/rules/sub dir/py;1.md", whole)],
            "path relative to the session directory": [self.read(os.path.relpath(rule, self.work), whole)],
            "symlink to the rules directory": [self.read(self.root / "profile/rules/sub dir/py;1.md")],
            "text blocks": [self.read(rule, [{"type": "text", "text": whole}, {"type": "image", "source": {}}])],
            "another line number format": [self.read(rule, arrows)],
            "after a call of another tool": [self.read(rule, "py;1.md", tool="Bash"), self.read(rule)],
        }
        for name, calls in cases.items():
            with self.subTest(name):
                self.session = next(self.sessions)
                self.batch_done(*calls)
                self.assertPasses(self.edit(self.work / "a.py"))
        self.assertEqual((self.state / self.session).read_text().splitlines(), [f"main {rule.resolve()}"])

    def test_a_read_that_does_not_show_the_whole_rule_leaves_the_edit_denied(self):
        rule = self.rule("py.md", ["**/*.py"])
        other = self.rule("txt.md", ["**/*.txt"])
        text = rule.read_text()
        lines, whole = text.split("\n"), self.numbered(text)
        cases = {
            "read from the second line": self.read(rule, self.numbered("\n".join(lines[1:]), first=2)),
            "read without the last lines": self.read(rule, self.numbered("\n".join(lines[:4]))),
            "a line cut short": self.read(rule, whole.replace("# py.md", "# py")),
            "an unchanged-file notice": self.read(rule, self.UNCHANGED),
            "no result": {"tool_name": "Read", "tool_input": {"file_path": str(rule)}},
            "a result object": self.read(rule, {"type": "text", "file": {"filePath": str(rule), "content": text}}),
            "another tool": self.read(rule, tool="Grep"),
            "another rule": self.read(other),
        }
        file = self.work / "a.py"
        for name, call in cases.items():
            with self.subTest(name):
                self.session = next(self.sessions)
                self.batch_done(call)
                self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")

    def test_a_read_of_a_file_that_is_not_a_rule_records_nothing(self):
        text = self.rule("py.md", ["**/*.py"]).read_text()
        copies = [self.work / "py.md", self.home / ".claude/rules-old/py.md", self.home / ".claude/rules/py.txt"]
        for copy in copies:
            copy.parent.mkdir(parents=True, exist_ok=True)
            copy.write_text(text)
            with self.subTest(copy):
                self.batch_done(self.read(copy))
        self.assertEqual(self.state_files(), [])

    def test_a_read_counts_only_for_the_agent_that_made_it(self):
        rule = self.rule("py.md", ["**/*.py"])
        file = self.work / "a.py"
        self.batch_done(self.read(rule), agent_id="agent-1")
        self.assertPasses(self.edit(file, agent_id="agent-1"))
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")
        self.session = next(self.sessions)
        self.batch_done(self.read(rule))
        self.assertPasses(self.edit(file))
        self.assertDenied(self.edit(file, agent_id="agent-1"), file, "~/.claude/rules/py.md")

    def test_a_rule_read_drops_denied_edits(self):
        rule = self.rule("py.md", ["**/*.py"])
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")
        self.batch_done(self.read(rule))
        self.assertPasses(self.edit(self.work / "b.py"))
        self.assertEqual((self.state / self.session).read_text().splitlines(), [f"main {rule.resolve()}"])

    def test_malformed_tool_calls_record_nothing(self):
        rule = self.rule("py.md", ["**/*.py"])
        call = self.read(rule)
        relative = self.read(os.path.relpath(rule, self.work), call["tool_response"])
        cases = {
            "no tool_calls": {},
            "call that is a list": {"tool_calls": [[call]]},
            "no tool_input": {"tool_calls": [{k: v for k, v in call.items() if k != "tool_input"}]},
            "file_path with NUL": {"tool_calls": [{**call, "tool_input": {"file_path": f"{rule}\0"}}]},
            "result block that is not an object": {"tool_calls": [{**call, "tool_response": ["text"]}]},
            "text block without text": {"tool_calls": [{**call, "tool_response": [{"type": "text"}]}]},
            "cwd with NUL": {"tool_calls": [relative], "cwd": f"{self.work}\0"},
        }
        for name, fields in cases.items():
            with self.subTest(name):
                self.assertPasses(self.run_hook(self.event(hook_event_name="PostToolBatch", **fields)), name)
        self.assertEqual(self.state_files(), [])

    def test_a_read_of_an_unusable_rule_file_records_nothing(self):
        rules = self.home / ".claude/rules"
        os.mkfifo(rules / "fifo.md")
        (rules / "dangling.md").symlink_to(self.root / "missing.md")
        real = self.rule("nl\nname.md", ["**/*.py"], directory=self.root / "elsewhere")
        (rules / "newline.md").symlink_to(real)
        calls = {"fifo": self.read(rules / "fifo.md", ""),
                 "dangling symlink": self.read(rules / "dangling.md", "File does not exist."),
                 "target path with a newline": self.read(rules / "newline.md")}
        for name, call in calls.items():
            with self.subTest(name):
                self.batch_done(call)
        self.assertEqual(self.state_files(), [])


class WorkingFolderTests(RuleGateTestCase):
    def test_claude_project_dir_wins_over_cwd(self):
        self.rule("src.md", ["src/*.py"])
        other = self.root / "other"
        other.mkdir()
        file = self.work / "src/a.py"
        project = dict(self.env, CLAUDE_PROJECT_DIR=str(self.work))
        self.assertDenied(self.edit(file, cwd=other, env=project), file, "~/.claude/rules/src.md")
        elsewhere = dict(self.env, CLAUDE_PROJECT_DIR=str(other))
        self.assertPasses(self.edit(file, cwd=self.work, env=elsewhere))

    def test_cwd_is_used_when_claude_project_dir_is_unset(self):
        self.rule("src.md", ["src/*.py"])
        file = self.work / "src/a.py"
        self.assertDenied(self.edit(file, cwd=self.work), file, "~/.claude/rules/src.md")
        self.session = next(self.sessions)
        self.assertPasses(self.edit(file, cwd=self.root / "other"))

    def test_symlinked_working_folder_resolves(self):
        self.rule("src.md", ["src/*.py"])
        link = self.root / "link"
        link.symlink_to(self.work)
        file = self.work / "src/a.py"
        self.assertDenied(self.edit(file, cwd=link), file, "~/.claude/rules/src.md")
        self.session = next(self.sessions)
        self.assertDenied(self.edit(link / "src/a.py", cwd=self.work), link / "src/a.py", "~/.claude/rules/src.md")

    def test_files_outside_the_folder_match_relative_to_home_then_absolute(self):
        self.rule("home.md", ["proj/*.py"])
        file = self.home / "proj/a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/home.md")
        self.assertPasses(self.edit(self.outside / "proj/a.py"))
        absolute = self.rule("abs.md", [f"{self.outside}/**/*.py"])
        file = self.outside / "proj/a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/abs.md")
        self.assertEqual(absolute.name, "abs.md")

    def test_folder_match_wins_over_home_for_a_folder_inside_home(self):
        self.rule("src.md", ["src/*.py"])
        inside = self.home / "repo"
        (inside / "src").mkdir(parents=True)
        file = inside / "src/a.py"
        self.assertDenied(self.edit(file, cwd=inside), file, "~/.claude/rules/src.md")


class SkipTests(RuleGateTestCase):
    def test_scratch_locations_pass_without_a_record(self):
        self.rule("py.md", ["**/*.py", "**/*.md"])
        cases = {
            "tmpdir": self.root / "tmp/a.py",
            "claude-tmp": self.root / "cache/claude-tmp/session/a.py",
            "scratch in the folder": self.work / ".cache/agents/scratch/task/a.py",
            "scratch elsewhere": self.outside / "x/.cache/agents/scratch/a.py",
            "scratch in home": self.home / ".cache/agents/scratch/t/notes.md",
        }
        for name, file in cases.items():
            with self.subTest(name):
                self.assertPasses(self.edit(file))
        self.assertEqual(self.state_files(), [])

    def test_similar_paths_are_not_skipped(self):
        self.rule("py.md", ["**/*.py"])
        for file in (self.root / "tmp-other/a.py", self.work / ".cache/agents/other/a.py",
                     self.work / ".cache/scratch/a.py", self.root / "cache/claude-tmpx/a.py"):
            with self.subTest(file=file):
                self.session = next(self.sessions)
                self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")

    def test_symlink_into_tmpdir_is_skipped(self):
        self.rule("py.md", ["**/*.py"])
        link = self.work / "tmplink"
        link.symlink_to(self.root / "tmp")
        self.assertPasses(self.edit(link / "a.py"))


class GlobTests(RuleGateTestCase):
    CASES = [
        ("**/*.yml", ".github/workflows/ci.yml", True),
        ("**/*.yml", ".gitlab-ci.yml", True),
        ("**/*.py", "a.py", True),
        ("**/*.py", "a/b/c/d.py", True),
        ("*.py", "a.py", True),
        ("*.py", "sub/a.py", True),
        ("src/**/*.py", "src/a.py", True),
        ("src/**/*.py", "src/x/y/a.py", True),
        ("src/**/*.py", "lib/a.py", False),
        ("src/**", "src/x/a.txt", True),
        ("src/*", "src/a/b/c", True),
        ("**/scripts/*", "scripts/sub/build", True),
        ("**/scripts/*", "pkg/scripts/build", True),
        ("**/scripts/*", "scripts", False),
        ("**/{executable,modify}_*", "executable_bash-guard.py", True),
        ("**/{executable,modify}_*", "home/dot_claude/hooks/modify_x.sh", True),
        ("**/{executable,modify}_*", "other_x", False),
        ("**/{a,{b,c}}_x", "c_x", True),
        ("**/{a,{b,c}}_x", "d_x", False),
        ("{src,lib}/**/*.ts", "lib/x/a.ts", True),
        ("{src,lib}/**/*.ts", "test/a.ts", False),
        ("**/*.{ts,tsx}", "a/b.tsx", True),
        ("**/*.{ts,tsx}", "a/b.js", False),
        ("a?c.py", "abc.py", True),
        ("a?c.py", "ac.py", False),
        ("a?c.py", "a/c.py", False),
        ("**/*.PY", "a.py", False),
        ("**/*.py", "a.PY", False),
        ("**/a{b", "a{b", True),
        ("**/a}b", "a}b", True),
        ("**/a.py", "ba.py", False),
        ("*.[ch]", "a.c", True),
        ("**/a+b(1).py", "a+b(1).py", True),
        ("*.zq", "sub/a.zq", True),
        ("*.zq", ".hidden/x/a.zq", True),
        ("*.zq", "sub/a.zr", False),
        ("docs/", "x/docs/a.md", True),
        ("docs/", "x/other/a.md", False),
        ("src/*.py", "lib/src/a.py", False),
        ("/*.zr", "c.zr", True),
        ("/*.zr", "sub/b.zr", False),
        ("/src/*.py", "src/a.py", True),
        ("/src/*.py", "lib/src/a.py", False),
        ("**/*.[xy]q", "sub/d.xq", True),
        ("**/*.[xy]q", "d.yq", True),
        ("**/*.[xy]q", "sub/d.zq", False),
        ("**/*.[a-c]q", "b.q", False),
        ("**/*.[a-c]q", "x.bq", True),
        ("**/*.[!xy]q", "d.zq", True),
        ("**/*.[!xy]q", "d.xq", False),
        ("**/*.[^xy]q", "d.zq", True),
        ("**/*.[^xy]q", "d.yq", False),
        ("a[!x]b", "a/b", False),
        ("a[]x]b", "a]b", True),
        ("[!]x", "ay", False),
        ("[!]x", "[!]x", True),
        ("*.[a", "x.[a", True),
        ("*.[a", "x.a", False),
        ("*.[!", "x.[!", True),
        ("*.[z-a]", "x.a", False),
        ("*.[z-a]", "x.[z-a]", False),
        ("**/[+--]*.zq", "+a.zq", True),
        ("**/[+--]*.zq", ",a.zq", True),
        ("**/[+--]*.zq", "-a.zq", True),
        ("**/[+--]*.zq", "a.zq", False),
    ]

    def test_globs_match_like_claude_code(self):
        for glob, path, expected in self.CASES:
            with self.subTest(glob=glob, path=path):
                self.session = next(self.sessions)
                self.rule("g.md", [glob])
                result = self.edit(self.work / path)
                if expected:
                    self.assertDenied(result, self.work / path, "~/.claude/rules/g.md")
                else:
                    self.assertPasses(result)

    def test_globs_match_outside_the_working_folder_by_absolute_path(self):
        self.rule("g.md", ["**/*.yml"])
        file = self.outside / ".github/ci.yml"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/g.md")

    def test_frontmatter_forms(self):
        rules = self.home / ".claude/rules"
        (rules / "plain.md").write_text("---\ndescription: x\npaths:\n  - **/*.a\n  - '**/*.b'\n  # c\n  - \"**/*.c\"\n"
                                        "other: y\n  - **/*.d\n---\n- **/*.e\n")
        (rules / "nofront.md").write_text("paths:\n  - **/*.f\n")
        (rules / "late.md").write_text("# title\n---\npaths:\n  - **/*.g\n---\n")
        (rules / "open.md").write_text("---\npaths:\n  - **/*.h\n")
        for ext, expected in (("a", True), ("b", True), ("c", True), ("d", False), ("e", False), ("f", False),
                              ("g", False), ("h", False)):
            with self.subTest(ext=ext):
                self.session = next(self.sessions)
                result = self.edit(self.work / f"x.{ext}")
                if expected:
                    self.assertDenied(result, self.work / f"x.{ext}", "~/.claude/rules/plain.md")
                else:
                    self.assertPasses(result)

    def test_a_reversed_range_disables_only_its_own_glob(self):
        self.rule("g.md", ["*.[z-a]", "**/*.py"])
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/g.md")

    def test_unindented_list_items_and_comma_separated_strings(self):
        rules = self.home / ".claude/rules"
        (rules / "unindented.md").write_text('---\npaths:\n- "**/*.zu"\n- \'**/*.zv\'\n---\n')
        (rules / "quoted-csv.md").write_text('---\npaths: "**/*.zc, **/*.zd"\n---\n')
        (rules / "plain-csv.md").write_text("---\npaths: **/*.pa, **/*.{pb,pc}\n---\n")
        (rules / "item-csv.md").write_text('---\npaths: "**/*.ia", \'**/*.ib\'\n---\n')
        cases = {"zu": "unindented.md", "zv": "unindented.md", "zc": "quoted-csv.md", "zd": "quoted-csv.md",
                 "pa": "plain-csv.md", "pb": "plain-csv.md", "pc": "plain-csv.md", "ia": "item-csv.md",
                 "ib": "item-csv.md", "zx": None, "p": None}
        for ext, name in cases.items():
            with self.subTest(ext=ext):
                self.session = next(self.sessions)
                file = self.work / f"sub/x.{ext}"
                if name:
                    self.assertDenied(self.edit(file), file, f"~/.claude/rules/{name}")
                else:
                    self.assertPasses(self.edit(file))

    def test_flow_lists_byte_order_marks_and_negated_globs(self):
        rules = self.home / ".claude/rules"
        (rules / "flow.md").write_text('---\npaths: ["**/*.zj", \'**/*.{ya,yb}\', "**/*.[cd]z"]\n---\n')
        (rules / "bom.md").write_text('﻿---\npaths:\n  - "**/*.zk"\n---\n', encoding="utf-8")
        self.rule("bang.md", ["**/*.zo", "!**/skip/*.zo"])
        self.rule("readd.md", ["**/*.zp", "!**/skip/*.zp", "**/skip/keep.zp"])
        cases = {"sub/x.zj": "flow.md", "sub/x.ya": "flow.md", "sub/x.yb": "flow.md", "sub/x.dz": "flow.md",
                 "sub/x.zk": "bom.md", "sub/x.zo": "bang.md", "skip/y.zo": None, "skip/y.zp": None,
                 "skip/keep.zp": "readd.md"}
        for path, name in cases.items():
            with self.subTest(path=path):
                self.session = next(self.sessions)
                file = self.work / path
                if name:
                    self.assertDenied(self.edit(file), file, f"~/.claude/rules/{name}")
                else:
                    self.assertPasses(self.edit(file))

    def test_multi_line_flow_lists_comments_and_key_spacing(self):
        rules = self.home / ".claude/rules"
        (rules / "ml.md").write_text('---\npaths: [\n  "**/*.ml1",  # first\n  "**/*.ml2"\n]\n---\n')
        (rules / "tc.md").write_text('---\npaths: ["**/*.tc"] # note\n---\n')
        (rules / "sc.md").write_text('---\npaths : ["**/*.sc"]\n---\n')
        (rules / "ic.md").write_text('---\npaths:\n  - "**/*.ic" # note\n  - "**/#*.hc"\n---\n')
        cases = {"sub/x.ml1": "ml.md", "sub/x.ml2": "ml.md", "sub/x.tc": "tc.md", "sub/x.sc": "sc.md",
                 "sub/x.ic": "ic.md", "sub/#x.hc": "ic.md"}
        for path, name in cases.items():
            with self.subTest(path=path):
                self.session = next(self.sessions)
                file = self.work / path
                self.assertDenied(self.edit(file), file, f"~/.claude/rules/{name}")

    def test_rules_in_subdirectories_are_named_by_their_path(self):
        self.rule("sub/nested.md", ["**/*.zn"])
        self.rule("sub/deeper/more.md", ["**/*.zn"])
        self.rule("top.md", ["**/*.zn"])
        (self.home / ".claude/rules/sub/ignored.txt").write_text("---\npaths:\n  - \"**/*.zn\"\n---\n")
        file = self.work / "sub/g.zn"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/sub/deeper/more.md, ~/.claude/rules/sub/nested.md, "
                          "and ~/.claude/rules/top.md")
        self.batch_done()
        self.assertPasses(self.edit(file))
        lines = (self.state / self.session).read_text().splitlines()
        self.assertIn(f"main {(self.home / '.claude/rules/sub/nested.md').resolve()}", lines)
        self.assertEqual(len(lines), 3)

    def test_symlinked_subdirectory_is_followed_once(self):
        self.rule("real.md", ["**/*.py"], directory=self.root / "elsewhere")
        rules = self.home / ".claude/rules"
        (rules / "link").symlink_to(self.root / "elsewhere")
        (rules / "loop").symlink_to(rules)
        (self.root / "elsewhere/back").symlink_to(rules)
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/link/real.md")

    def test_sibling_directories_for_one_real_directory_list_a_rule_once(self):
        self.rule("real.md", ["**/*.py"], directory=self.root / "elsewhere")
        rules = self.home / ".claude/rules"
        for name in ("b", "a", "c"):
            (rules / name).symlink_to(self.root / "elsewhere")
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/a/real.md")

    def test_a_fifo_rule_is_skipped_without_blocking(self):
        rules = self.home / ".claude/rules"
        os.mkfifo(rules / "fifo.md")
        (rules / "link.md").symlink_to(rules / "fifo.md")
        self.rule("py.md", ["**/*.py"])
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")

    def test_a_rule_that_is_a_fifo_when_opened_has_no_globs(self):
        spec = importlib.util.spec_from_file_location("rule_gate", HOOK)
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        fifo = self.root / "fifo.md"
        os.mkfifo(fifo)
        globs = []
        thread = threading.Thread(target=lambda: globs.append(module.rule_globs(fifo)), daemon=True)
        thread.start()
        thread.join(5)
        blocked = thread.is_alive()
        if blocked:
            os.close(os.open(fifo, os.O_WRONLY))
            thread.join()
        self.assertFalse(blocked, "opening the FIFO blocked")
        self.assertEqual(globs, [[]])

    def test_symlinked_rule_file_is_followed_and_recorded_by_realpath(self):
        real = self.rule("real.md", ["**/*.py"], directory=self.root / "elsewhere")
        (self.home / ".claude/rules/link.md").symlink_to(real)
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/link.md")
        self.session = next(self.sessions)
        self.loaded("path_glob_match", real)
        self.assertPasses(self.edit(file))

    def test_symlinked_rules_directory_is_followed(self):
        self.rule("real.md", ["**/*.py"], directory=self.root / "elsewhere")
        (self.home / ".claude/rules").rmdir()
        (self.home / ".claude/rules").symlink_to(self.root / "elsewhere")
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/real.md")


class FailOpenTests(RuleGateTestCase):
    def test_malformed_input_passes(self):
        self.rule("py.md", ["**/*.py"])
        for raw in ("", "not json", "[]", "null", '{"hook_event_name": "PreToolUse"', "\xff", "[" * 1_000_000,
                    "[" * 1_000_000 + "]" * 1_000_000):
            with self.subTest(raw=raw[:40]):
                self.assertPasses(self.run_hook(None, raw=raw))

    def test_missing_or_invalid_fields_pass(self):
        self.rule("py.md", ["**/*.py"])
        file = str(self.work / "a.py")
        base = {"hook_event_name": "PreToolUse", "tool_name": "Edit", "session_id": "s", "cwd": str(self.work),
                "tool_input": {"file_path": file}}
        cases = {
            "no tool_input": {k: v for k, v in base.items() if k != "tool_input"},
            "tool_input list": {**base, "tool_input": []},
            "no file_path": {**base, "tool_input": {}},
            "file_path number": {**base, "tool_input": {"file_path": 3}},
            "empty file_path": {**base, "tool_input": {"file_path": ""}},
            "file_path with NUL": {**base, "tool_input": {"file_path": file + "\0.py"}},
            "file_path with a lone surrogate": {**base, "tool_input": {"file_path": file + "\ud800.py"}},
            "cwd with NUL": {**base, "cwd": str(self.work) + "\0", "tool_input": {"file_path": "a.py"}},
            "no session_id": {k: v for k, v in base.items() if k != "session_id"},
            "path traversal session": {**base, "session_id": "../evil"},
            "session with space": {**base, "session_id": "a b"},
            "agent id with space": {**base, "agent_id": "a b"},
            "no cwd": {k: v for k, v in base.items() if k != "cwd"},
            "unknown event": {**base, "hook_event_name": "Stop"},
            "no event": {k: v for k, v in base.items() if k != "hook_event_name"},
        }
        for name, payload in cases.items():
            with self.subTest(name):
                self.assertPasses(self.run_hook(payload), name)
        self.assertFalse((self.root / "state/agents/evil").exists())
        self.assertEqual(self.state_files(), [])

    def test_unusable_cwd_passes_when_claude_project_dir_is_set(self):
        self.rule("py.md", ["**/*.py"])
        project = dict(self.env, CLAUDE_PROJECT_DIR=str(self.work))
        for cwd in (str(self.work) + "\0", str(self.work) + "\ud800"):
            with self.subTest(cwd=cwd):
                self.assertPasses(self.run_hook(self.event(
                    hook_event_name="PreToolUse", tool_name="Edit", tool_input={"file_path": str(self.work / "a.py")},
                    cwd=cwd), env=project))
        self.assertEqual(self.state_files(), [])

    def test_missing_rules_directory_passes(self):
        (self.home / ".claude/rules").rmdir()
        self.assertPasses(self.edit(self.work / "a.py"))

    @unittest.skipIf(os.geteuid() == 0, "root reads every file")
    def test_unreadable_rule_file_is_skipped(self):
        unreadable = self.rule("a-locked.md", ["**/*.py"])
        self.rule("b-open.md", ["**/*.py"])
        unreadable.chmod(0)
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/b-open.md")

    def test_dangling_rule_symlink_is_skipped(self):
        (self.home / ".claude/rules/dangling.md").symlink_to(self.root / "missing.md")
        self.assertPasses(self.edit(self.work / "a.py"))

    def test_unwritable_state_directory_shows_a_failure_and_passes(self):
        self.rule("py.md", ["**/*.py"])
        blocked = dict(self.env, XDG_STATE_HOME=str(self.root / "blocker/state"))
        (self.root / "blocker").write_text("a file, not a directory")
        self.assertHookFailed(self.edit(self.work / "a.py", env=blocked), r"\[Errno 20\] Not a directory: '.+'")

    @unittest.skipIf(os.geteuid() == 0, "root reads every directory")
    def test_a_batch_end_shows_a_state_directory_failure(self):
        self.rule("py.md", ["**/*.py"])
        file = self.work / "a.py"
        self.assertDenied(self.edit(file), file, "~/.claude/rules/py.md")
        self.state.chmod(0)
        try:
            result = self.run_hook(self.event(hook_event_name="PostToolBatch", tool_calls=[]))
        finally:
            self.state.chmod(0o755)
        self.assertHookFailed(result, r"\[Errno 13\] Permission denied: '.+'")

    def test_a_failed_state_write_keeps_the_old_records(self):
        self.rule("py.md", ["**/*.py"])
        first = self.work / "a.py"
        self.assertDenied(self.edit(first), first, "~/.claude/rules/py.md")
        saved = (self.state / self.session).read_bytes()

        def limit_file_size():
            resource.setrlimit(resource.RLIMIT_FSIZE, (len(saved), len(saved)))

        payload = self.event(hook_event_name="PreToolUse", tool_name="Edit",
                             tool_input={"file_path": str(self.work / "b.py")})
        result = subprocess.run([sys.executable, "-I", str(HOOK)], env=self.env, capture_output=True, text=True,
                                input=json.dumps(payload), timeout=30, preexec_fn=limit_file_size)
        self.assertHookFailed(result, r"\[Errno 27\] File too large")
        self.assertEqual((self.state / self.session).read_bytes(), saved)
        self.assertEqual(self.state_files(), [self.session])

    def test_a_rule_symlink_whose_target_path_has_a_newline_is_not_recorded(self):
        real = self.rule("nl\nname.md", ["**/*.py"], directory=self.root / "elsewhere")
        (self.home / ".claude/rules/link.md").symlink_to(real)
        self.loaded("path_glob_match", self.home / ".claude/rules/link.md")
        self.assertEqual(self.state_files(), [])

    def test_rule_loads_with_unusable_paths_keep_the_other_records(self):
        rule = self.rule("py.md", ["**/*.py"])
        self.loaded("path_glob_match", rule)
        self.loaded("path_glob_match", f"{self.root}/x\udcff.md")
        self.loaded("path_glob_match", f"{self.root}/x\ud800.md")
        self.assertPasses(self.edit(self.work / "a.py"))
        lines = (self.state / self.session).read_bytes().splitlines()
        self.assertEqual(lines, [f"main {rule.resolve()}".encode(), f"main {self.root}/x".encode() + b"\xff.md"])


class PruneTests(RuleGateTestCase):
    def age(self, name, days):
        path = self.state / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("main /x\n")
        stamp = time.time() - days * 24 * 3600
        os.utime(path, (stamp, stamp))

    def test_state_files_older_than_a_week_are_deleted(self):
        self.age("old-session", 8)
        self.age("recent-session", 6)
        self.assertPasses(self.edit(self.work / "a.py"))
        self.assertEqual(self.state_files(), ["recent-session"])

    def test_pruning_also_runs_when_the_rules_match(self):
        self.rule("py.md", ["**/*.py"])
        self.age("old-session", 8)
        self.edit(self.work / "a.py")
        self.assertEqual(self.state_files(), [self.session])


class RegistrationTests(unittest.TestCase):
    def setUp(self):
        text = SETTINGS.read_text().split("cat <<'JSON'\n", 1)[1].split("\nJSON\n", 1)[0]
        self.hooks = json.loads(text)["hooks"]
        self.command = {"type": "command", "command": "python3 -I ~/.claude/hooks/rule-gate.py", "timeout": 5}

    def test_pre_tool_use_runs_after_edit_guard_in_the_same_group(self):
        groups = [g for g in self.hooks["PreToolUse"] if any("edit-guard.py" in h["command"] for h in g["hooks"])]
        self.assertEqual(len(groups), 1)
        commands = [h["command"] for h in groups[0]["hooks"]]
        self.assertEqual(commands, ["python3 -I ~/.claude/hooks/edit-guard.py", self.command["command"]])
        self.assertEqual(groups[0]["hooks"][1], self.command)
        for tool in ("Edit", "Write", "MultiEdit"):
            self.assertTrue(re.fullmatch(groups[0]["matcher"], tool), tool)

    def test_instructions_loaded_has_one_group_without_a_matcher(self):
        groups = self.hooks["InstructionsLoaded"]
        self.assertEqual(len(groups), 1)
        self.assertNotIn("matcher", groups[0])
        self.assertEqual(groups[0]["hooks"], [self.command])

    def test_pre_compact_has_one_group_without_a_matcher(self):
        groups = self.hooks["PreCompact"]
        self.assertEqual(len(groups), 1)
        self.assertNotIn("matcher", groups[0])
        self.assertEqual(groups[0]["hooks"], [self.command])

    def test_post_tool_batch_has_one_group_without_a_matcher(self):
        groups = self.hooks["PostToolBatch"]
        self.assertEqual(len(groups), 1)
        self.assertNotIn("matcher", groups[0])
        self.assertEqual(groups[0]["hooks"], [self.command])


if __name__ == "__main__":
    unittest.main()
