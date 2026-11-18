"""Check the review-trial gate and report against an isolated state directory and fixture stores."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
REVIEW_TRIAL = REPO / "home/private_dot_local/bin/executable_review-trial"

# Stands in for `agt sessions report`: prices every transcript argument at 1.5 USD.
FAKE_AGT = """#!/bin/sh
printf '{"rows":['
separator=
for argument in "$@"; do
  case "$argument" in
    *.jsonl) printf '%s{"file":"%s","usd":1.5}' "$separator" "$argument"; separator=, ;;
  esac
done
printf ']}\\n'
"""


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

    def review_trial(self, command):
        result = subprocess.run(
            [str(REVIEW_TRIAL), command], cwd=self.repo, env=self.env, capture_output=True, text=True, check=False
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def write_fable_reviewer_transcript(self, agent_id, started_at, cwd):
        subagents = self.home / ".claude/projects/project/session/subagents"
        subagents.mkdir(parents=True, exist_ok=True)
        (subagents / f"agent-{agent_id}.meta.json").write_text(json.dumps({"agentType": "reviewer-fable"}))
        first_reply = {
            "type": "assistant",
            "timestamp": started_at,
            "cwd": str(cwd),
            "message": {"model": "claude-fable-5-2"},
        }
        (subagents / f"agent-{agent_id}.jsonl").write_text(json.dumps(first_reply) + "\n")

    def test_start_reserves_slots_until_the_limit(self):
        self.assertEqual(self.review_trial("status"), "on 0/20")
        self.assertEqual(self.review_trial("status"), "on 0/20")

        lines = [self.review_trial("start") for _ in range(21)]

        self.assertEqual(lines[0], "on 1/20")
        self.assertEqual(lines[19], "on 20/20")
        self.assertEqual(lines[20], "off 20/20")
        self.assertEqual(self.review_trial("status"), "off 20/20")

    def test_report_counts_each_model_once_per_finding(self):
        slots = self.home / "state/agents/review-trial/slots.tsv"
        slots.parent.mkdir(parents=True)
        slots.write_text(f"2020-01-02T00:00:00Z\t{self.repo}\n")
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
        store = {
            "runs": [
                {"id": "rv-trial", "started_at": "2020-01-03T00:00:00Z", "passes": [trial_pass]},
                {"id": "rv-plain", "started_at": "2020-01-03T00:00:00Z", "passes": [opus_only_pass]},
                {"id": "rv-early", "started_at": "2020-01-01T00:00:00Z", "passes": [trial_pass]},
            ],
            "threads": [
                thread("rv-trial.c1p0.r1.f1", severity="high"),
                thread("rv-trial.c1p0.r2.f1"),
                thread("rv-trial.c1p0.r3.f1", resolution="rejected: intended"),
                thread("rv-trial.c1p0.r5.f1"),
                thread("rv-plain.c1p0.r1.f1"),
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

        lines = self.review_trial("report").splitlines()

        self.assertEqual(lines[0], "trial reviews: 1; slots 1/20")
        self.assertEqual(lines[1].split("\t"), ["model", "reviews", "found", "only", "high", "medium", "killed", "usd"])
        self.assertEqual(
            [line.split("\t") for line in lines[2:]],
            [
                ["opus", "1", "1", "0", "1", "0", "0", "?"],
                ["fable", "1", "2", "1", "1", "1", "0", "1.50"],
                ["sonnet", "1", "0", "0", "0", "0", "1", "?"],
                ["haiku", "1", "0", "0", "0", "0", "1", "?"],
            ],
        )


if __name__ == "__main__":
    unittest.main()
