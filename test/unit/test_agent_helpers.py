"""Check agent-probe variant names without running agents."""
import argparse
import importlib.machinery
import importlib.util
from pathlib import Path
import unittest

REPO = Path(__file__).resolve().parents[2]
BIN = REPO / "home/private_dot_local/bin"


def load_probe():
    loader = importlib.machinery.SourceFileLoader("agent_probe", str(BIN / "executable_agent-probe"))
    spec = importlib.util.spec_from_loader("agent_probe", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class AgentProbeVariantTests(unittest.TestCase):
    def test_names_that_leave_the_output_directory_are_rejected(self):
        probe = load_probe()
        for spec in ("../baseline=", "/absolute=", "a/b=", ".hidden=", "a\\b="):
            with self.subTest(spec), self.assertRaises(argparse.ArgumentTypeError):
                probe.parse_variant(spec)

    def test_plain_names_are_accepted(self):
        probe = load_probe()
        self.assertEqual(probe.parse_variant("base="), ("base", []))
        self.assertEqual(probe.parse_variant("tool-search_off.2=--x")[0], "tool-search_off.2")


if __name__ == "__main__":
    unittest.main()
