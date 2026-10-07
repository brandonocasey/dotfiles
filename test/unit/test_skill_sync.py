"""Check skill deletion behavior with an isolated chezmoi source and home."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]


class SkillSyncTests(unittest.TestCase):
    def test_apply_removes_deleted_skills_and_nested_files(self):
        binary = shutil.which("chezmoi")
        self.assertIsNotNone(binary, "Install chezmoi to run the skill sync regression")
        scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="skill-sync-test-", dir=scratch) as directory:
            root = Path(directory)
            source = root / "source"
            home = root / "home"
            (home / ".config/agents").mkdir(parents=True)
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(root / "config"),
                       XDG_CACHE_HOME=str(root / "cache"), XDG_STATE_HOME=str(root / "state"))
            skills_source = next(
                path for path in (REPO / "home/dot_config/agents").iterdir()
                if path.name.removeprefix("exact_") == "skills"
            )
            fixture_skills = source / "dot_config/agents" / skills_source.name
            fixture_skills.mkdir(parents=True)
            # Use the real directory attributes without copying personal skill content.
            for path in skills_source.rglob("*"):
                target = fixture_skills / path.relative_to(skills_source)
                if path.is_dir():
                    target.mkdir(parents=True, exist_ok=True)
                else:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text("fixture\n")
            (source / ".chezmoiignore").write_text((REPO / "home/.chezmoiignore").read_text())
            config = root / "chezmoi.toml"
            config.write_text("[git]\nautoCommit = false\nautoPush = false\n")
            command = [binary, "--source", str(source), "--destination", str(home),
                       "--config", str(config), "--cache", str(root / "chezmoi-cache"),
                       "--persistent-state", str(root / "chezmoi-state.boltdb"), "--no-tty"]
            skills = home / ".config/agents/skills"

            def apply():
                result = subprocess.run(
                    command + ["apply", "--exclude=scripts", "--force", str(skills)],
                    env=env, capture_output=True, text=True, timeout=20)
                self.assertEqual(result.returncode, 0, result.stderr)

            references = next(path for path in fixture_skills.rglob("*")
                              if path.is_dir() and path.name.removeprefix("exact_") == "references")
            removed_file = references / "removed-reference.md"
            removed_file.write_text("previously managed\n")
            retired = fixture_skills / "exact_retired-skill"
            retired.mkdir()
            (retired / "SKILL.md").write_text("previously managed\n")
            apply()
            installed_reference = skills.joinpath(
                *(part.removeprefix("exact_") for part in removed_file.relative_to(fixture_skills).parts)
            )
            self.assertTrue(installed_reference.exists())
            removed_file.unlink()
            shutil.rmtree(retired)
            ignored = skills / "synced/account/example/SKILL.md"
            ignored.parent.mkdir(parents=True)
            ignored.write_text("Claude owns this\n")
            upstream_extra = skills / "frontend-design/upstream-resource.txt"
            upstream_extra.write_text("GitHub CLI owns this\n")
            untracked = installed_reference.parent / "untracked-reference.md"
            untracked.write_text("stale\n")
            probes = []
            for path in (skills_source, *skills_source.rglob("*")):
                if not path.is_dir() or "frontend-design" in path.relative_to(skills_source).parts:
                    continue
                installed = skills.joinpath(
                    *(part.removeprefix("exact_") for part in path.relative_to(skills_source).parts)
                )
                probe = installed / "stale-sync-probe.txt"
                probe.write_text("stale at this depth\n")
                probes.append(probe)
            neighbor = home / ".config/agents/local-only.txt"
            neighbor.write_text("outside skill scope\n")
            apply()
            self.assertFalse(installed_reference.exists(), "Deleted nested sources must disappear")
            self.assertFalse((skills / "retired-skill").exists(), "Deleted skills must disappear")
            self.assertFalse(untracked.exists(), "Unmanaged files in owned skill folders must disappear")
            for probe in probes:
                self.assertFalse(probe.exists(), f"Remove stale files from {probe.parent}")
            self.assertEqual(ignored.read_text(), "Claude owns this\n")
            self.assertEqual(upstream_extra.read_text(), "GitHub CLI owns this\n")
            self.assertTrue(neighbor.exists())
            apply()
            for name in ("llm-tools", "rom-weaver-release-verify", "pr-unblock"):
                self.assertTrue((skills / name / "SKILL.md").exists(), f"Preserve {name}")


if __name__ == "__main__":
    unittest.main()
