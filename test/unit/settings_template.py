"""Read the Claude settings that the chezmoi modify template holds."""
import json
from pathlib import Path
import re

TEMPLATE = Path(__file__).resolve().parents[2] / "home/.chezmoitemplates/claude-settings-modify.sh"
ACTION_LINE = re.compile(r"\{\{[^{}]*\}\}")


def managed_settings():
    """Return the managed settings, keeping every entry a template condition wraps."""
    block = TEMPLATE.read_text().split("cat <<'JSON'\n", 1)[1].split("\nJSON\n", 1)[0]
    lines = [line for line in block.split("\n") if not ACTION_LINE.fullmatch(line.strip())]
    return json.loads("\n".join(lines))
