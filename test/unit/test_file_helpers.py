"""Check the rename, find-replace, extract, and URL helpers on disposable files."""
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
BIN = REPO / "home/private_dot_local/bin"


def scratch_root():
    scratch = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agents/scratch"
    scratch.mkdir(parents=True, exist_ok=True)
    return scratch


class HelperTestCase(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="file-helpers-", dir=scratch_root())
        self.root = Path(self.directory.name)
        env = {key: value for key, value in os.environ.items() if key != "DOTFILES_DIR"}
        self.env = dict(env, HOME=str(self.root))

    def tearDown(self):
        self.directory.cleanup()

    def helper(self, name, *args):
        return subprocess.run(["bash", str(BIN / f"executable_{name}"), *args], cwd=self.root,
                              env=self.env, capture_output=True, text=True, timeout=30)


class RenameTests(HelperTestCase):
    def test_existing_destination_is_not_overwritten(self):
        (self.root / "old.txt").write_text("old\n")
        (self.root / "new.txt").write_text("new\n")
        result = self.helper("rename", "old", "new")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("new.txt", result.stderr)
        self.assertEqual((self.root / "new.txt").read_text(), "new\n")
        self.assertEqual((self.root / "old.txt").read_text(), "old\n")

    def test_arguments_are_separate_pairs(self):
        (self.root / "a1").write_text("a")
        (self.root / "c1").write_text("c")
        result = self.helper("rename", "a", "b", "c", "d")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(sorted(path.name for path in self.root.iterdir()), ["b1", "d1"])

    def test_unpaired_argument_is_rejected(self):
        (self.root / "a1").write_text("a")
        self.assertNotEqual(self.helper("rename", "a", "b", "c").returncode, 0)
        self.assertTrue((self.root / "a1").exists())


class FindReplaceTests(HelperTestCase):
    def test_spaced_names_and_trailing_newlines_are_preserved(self):
        spaced = self.root / "dir with space/my file.txt"
        spaced.parent.mkdir()
        spaced.write_text("foo bar\n\n")
        plain = self.root / "plain.txt"
        plain.write_text("foo")
        result = self.helper("find-replace", "foo", "baz", ".")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(spaced.read_text(), "baz bar\n\n")
        self.assertEqual(plain.read_text(), "baz")


class ExtractTests(HelperTestCase):
    def make_tar(self, name, member, mode="w"):
        source = self.root / "src" / member
        source.parent.mkdir(exist_ok=True)
        source.write_text(member)
        with tarfile.open(self.root / name, mode) as archive:
            archive.add(source, arcname=member)

    def test_gzip_tar_is_extracted(self):
        self.make_tar("one.tgz", "f0", "w:gz")
        out = self.root / "out"
        out.mkdir()
        result = self.helper("extract", "-d", str(out), "one.tgz")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((out / "f0").is_file())

    def test_every_archive_is_extracted(self):
        for index in range(3):
            self.make_tar(f"a{index}.tar", f"f{index}")
        out = self.root / "out"
        out.mkdir()
        result = self.helper("extract", "-d", str(out), "a0.tar", "a1.tar", "a2.tar")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(sorted(path.name for path in out.iterdir()), ["f0", "f1", "f2"])

    def test_failed_extraction_returns_failure(self):
        (self.root / "bad.tgz").write_text("not an archive")
        result = self.helper("extract", "bad.tgz")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("failed to extract", result.stderr)


class UrlToolTests(HelperTestCase):
    def test_encode_and_decode_without_dotfiles_dir(self):
        encoded = self.helper("urlencode", "a b&c")
        self.assertEqual(encoded.returncode, 0, encoded.stderr)
        self.assertIn(encoded.stdout.strip(), ("a%20b%26c", "a+b%26c"))
        decoded = self.helper("urldecode", "a%20b%26c")
        self.assertEqual(decoded.returncode, 0, decoded.stderr)
        self.assertEqual(decoded.stdout.strip(), "a b&c")


if __name__ == "__main__":
    unittest.main()
