"""Check the review-trial gate and report against an isolated state directory and fixture stores."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
REVIEW_TRIAL = REPO / "home/private_dot_local/bin/executable_review-trial"

# Stands in for `agt sessions report`: prices each transcript argument at 1.5 USD per line.
FAKE_AGT = """#!/bin/sh
printf '{"rows":['
separator=
for argument in "$@"; do
  case "$argument" in
    *.jsonl)
      printf '%s{"file":"%s","usd":%s}' "$separator" "$argument" "$(awk 'END { print NR * 1.5 }' "$argument")"
      separator=, ;;
  esac
done
printf ']}\\n'
"""
REPORT_HEADER = ["model", "reviews", "found", "only", "high", "medium", "killed", "usd"]


def scratch_root():
    scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
    scratch.mkdir(parents=True, exist_ok=True)
    return scratch


def reviewer(reviewer_id, model):
    return {"id": reviewer_id, "model": model, "effort": "xhigh"}


def thread(finding_id, severity="medium", resolution=None):
    run, review_pass, reviewer_id, _ = finding_id.split(".")
    return {
        "id": finding_id,
        "finding": {"run": run, "pass": review_pass, "reviewer": reviewer_id},
        "type": "bug",
        "severity": severity,
        "resolution": resolution,
    }


class ReviewTrialTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="review-trial-", dir=scratch_root())
        self.root = Path(self.directory.name).resolve()
        self.addCleanup(self.directory.cleanup)
        self.home = self.root / "home"
        self.repo = self.root / "repo with space"
        fake_bin = self.root / "bin"
        for directory in (self.home, self.repo, fake_bin):
            directory.mkdir()
        (fake_bin / "agt").write_text(FAKE_AGT)
        (fake_bin / "agt").chmod(0o755)
        self.env = {
            "HOME": str(self.home),
            "XDG_STATE_HOME": str(self.home / "state"),
            "PATH": f"{fake_bin}:{os.environ['PATH']}",
        }
        subprocess.run(["git", "init", "--quiet", str(self.repo)], check=True, env=self.env)

    def review_trial(self, command, env=None):
        result = subprocess.run(
            [str(REVIEW_TRIAL), command], cwd=self.repo, env=env or self.env, capture_output=True, text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def write_fable_reviewer_transcript(self, agent_id, started_at, cwd):
        """Write a transcript whose second reply comes two hours after the trial pass ended."""
        subagents = self.home / ".claude/projects/project/session/subagents"
        subagents.mkdir(parents=True, exist_ok=True)
        (subagents / f"agent-{agent_id}.meta.json").write_text(json.dumps({"agentType": "reviewer-fable"}))
        replies = [
            {"type": "assistant", "timestamp": timestamp, "cwd": str(cwd), "message": {"model": "claude-fable-5-2"}}
            for timestamp in (started_at, "2020-01-03T03:00:00.000Z")
        ]
        blank_line = "\n"
        entries = blank_line + (blank_line * 2).join(json.dumps(reply) for reply in replies) + "\n"
        (subagents / f"agent-{agent_id}.jsonl").write_text(entries)

    def write_trial_fixture(self):
        """Write two slots, two overlapping trial runs, five non-trial runs, and five reviewer transcripts."""
        slots = self.home / "state/agents/review-trial/slots.tsv"
        slots.parent.mkdir(parents=True)
        slots.write_text(f"not-a-time\t{self.repo}\n2020-01-02T00:00:00Z\t{self.repo}\n2020-01-02T06:00:00\t{self.repo}\n")
        trial_pass = {
            "id": "c1p0",
            "kind": "full",
            "started_at": "2020-01-03T00:00:00Z",
            "ended_at": "2020-01-03T01:00:00Z",
            "reviewers": [
                reviewer("r1", "claude-opus-5-5"),
                reviewer("r2", "claude-fable-5-2"),
                reviewer("r3", "claude-sonnet-5-5"),
                reviewer("r4", "claude-haiku-5-5"),
                reviewer("r5", "claude-haiku-5-5"),
                reviewer("fix", "claude-haiku-5-5"),
            ],
            "killed": [
                {"id": "rv-trial.c1p0.r2.f2", "reason": "duplicate of rv-trial.c1p0.r1.f1"},
                {"id": "rv-trial.c1p0.r4.f1", "reason": "the guard on line 9 makes it unreachable"},
            ],
        }
        opus_only_reviewers = [reviewer("r1", "claude-opus-5-5"), reviewer("fix", "claude-fable-5-2")]
        opus_only_pass = dict(trial_pass, reviewers=opus_only_reviewers, killed=[])
        fable_only_reviewers = [reviewer("r1", "claude-fable-5-2"), reviewer("r2", "claude-haiku-5-5")]
        fable_only_pass = dict(trial_pass, reviewers=fable_only_reviewers, killed=[])
        open_pass = dict(trial_pass, ended_at=None, killed=[])
        no_haiku_code_reviewer_pass = dict(trial_pass, reviewers=trial_pass["reviewers"][:4], killed=[])
        wide_pass = dict(trial_pass, started_at="2020-01-02T23:30:00Z", ended_at="2020-01-03T04:00:00Z", killed=[])
        store = {
            "runs": [
                {"id": "rv-wide", "started_at": "2020-01-02T23:30:00Z", "passes": [wide_pass]},
                {"id": "rv-trial", "started_at": "2020-01-03T00:00:00Z", "passes": [trial_pass]},
                {"id": "rv-three", "started_at": "2020-01-03T00:00:00Z", "passes": [no_haiku_code_reviewer_pass]},
                {"id": "rv-plain", "started_at": "2020-01-03T00:00:00Z", "passes": [opus_only_pass]},
                {"id": "rv-agents", "started_at": "2020-01-03T00:00:00Z", "passes": [fable_only_pass]},
                {"id": "rv-open", "started_at": "2020-01-03T00:00:00Z", "passes": [open_pass]},
                {"id": "rv-early", "started_at": "2020-01-01T00:00:00Z", "passes": [trial_pass]},
            ],
            "threads": [
                thread("rv-trial.c1p0.r1.f1", severity="high"),
                thread("rv-trial.c1p0.r2.f1"),
                thread("rv-trial.c1p0.r3.f1", resolution="rejected: intended"),
                thread("rv-trial.c1p0.r5.f1"),
                thread("rv-plain.c1p0.r1.f1"),
                thread("rv-agents.c1p0.r2.f1"),
                thread("rv-three.c1p0.r4.f1"),
                thread("rv-open.c1p0.r2.f1"),
                thread("rv-early.c1p0.r2.f1"),
            ],
        }
        store_dir = self.repo / ".agt/reviews"
        store_dir.mkdir(parents=True)
        (store_dir / "branch-main.json").write_text(json.dumps(store))
        review_worktree = self.repo / ".worktrees/review"
        self.write_fable_reviewer_transcript("during", "2020-01-03T00:10:00.000Z", review_worktree)
        self.write_fable_reviewer_transcript("before", "2020-01-02T23:00:00.000Z", review_worktree)
        self.write_fable_reviewer_transcript("after", "2020-01-03T02:00:00.000Z", review_worktree)
        self.write_fable_reviewer_transcript("elsewhere", "2020-01-03T00:10:00.000Z", self.root / "other repo")
        self.write_fable_reviewer_transcript("unreadable", "not-a-time", review_worktree)

    def test_start_reserves_slots_until_the_limit(self):
        self.assertEqual(self.review_trial("status"), "on 0/20")
        self.assertEqual(self.review_trial("status"), "on 0/20")

        lines = [self.review_trial("start") for _ in range(21)]

        self.assertEqual(lines[0], "on 1/20")
        self.assertEqual(lines[19], "on 20/20")
        self.assertEqual(lines[20], "off 20/20")
        self.assertEqual(self.review_trial("status"), "off 20/20")

    def test_start_and_status_skip_the_same_malformed_slot_lines(self):
        slots = self.home / "state/agents/review-trial/slots.tsv"
        slots.parent.mkdir(parents=True)
        malformed_lines = f"not-a-time\t{self.repo}\n\xff\xfe\t{self.repo}\n2020-01-02T00:00:00Z\t\n"
        slot_without_line_end = f"2020-01-02T00:00:00Z\t{self.repo}"
        slots.write_bytes((malformed_lines + slot_without_line_end).encode("latin-1"))

        self.assertEqual(self.review_trial("status"), "on 1/20")
        self.assertEqual(self.review_trial("start"), "on 2/20")
        self.assertEqual(self.review_trial("status"), "on 2/20")

    def test_report_counts_each_model_once_per_finding(self):
        self.write_trial_fixture()

        lines = self.review_trial("report").splitlines()

        self.assertEqual(lines[0], "trial reviews: 2; slots 2/20")
        self.assertEqual(lines[1].split("\t"), REPORT_HEADER)
        # Fable cost: cut "during" at rv-trial's end (1 reply) and "after" at rv-wide's end (2).
        self.assertEqual(
            [line.split("\t") for line in lines[2:]],
            [
                ["opus", "2", "1", "0", "1", "0", "0", "?"],
                ["fable", "2", "2", "1", "1", "1", "0", "4.50"],
                ["sonnet", "2", "0", "0", "0", "0", "1", "?"],
                ["haiku", "2", "0", "0", "0", "0", "1", "?"],
            ],
        )

    def test_report_prints_findings_when_agt_is_missing(self):
        self.write_trial_fixture()

        lines = self.review_trial("report", env=dict(self.env, PATH="/usr/bin:/bin")).splitlines()

        self.assertEqual(lines[3].split("\t"), ["fable", "2", "2", "1", "1", "1", "0", "?"])


if __name__ == "__main__":
    unittest.main()
