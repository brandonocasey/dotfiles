#!/usr/bin/env python3
"""PreToolUse guard for Bash. Blocks two patterns that waste sessions.

- Foreground polling: until/while loops that sleep, sleeps of 20s or more,
  and gh watch commands. They hit the 10-minute tool cap and leave the context
  idle while its cache expires. Background runs pass.
- pkill -f / pgrep -f with a plain pattern. The pattern also appears in this
  shell's own command line, so pkill kills its own shell (exit 144) and pgrep
  always finds a match.

Exit 2 cancels the call and shows the message to the model.
"""

import json
import re
import sys

POLL_LOOP = re.compile(r"\b(until|while)\b[^\n]*?\bdo\b(?:(?!\bdone\b)[\s\S])*?\bsleep\b")
SLEEP = re.compile(r"\bsleep\s+(\d+(?:\.\d+)?)([smhd]?)\b")
UNIT = {"": 1, "s": 1, "m": 60, "h": 3600, "d": 86400}
# Quoted arguments are data (search patterns, commit messages), except the
# script given to `sh -c` and friends.
QUOTED = re.compile(r"(?<!-c )(\"[^\"]*\"|'[^']*')")
GH_WATCH = re.compile(r"\bgh\s+(pr\s+checks\b[^\n|;&]*--watch|run\s+watch)\b")
PROC_MATCH = re.compile(
    r"\b(pkill|pgrep)\b((?:\s+-[A-Za-z]+)*?\s+-[A-Za-z]*f[A-Za-z]*(?:\s+-[A-Za-z]+)*)\s+"
    r"(\"[^\"]*\"|'[^']*'|[^\s;|&]+)"
)


HEREDOC = re.compile(r"<<-?[ \t]*(['\"]?)(\w+)\1[^\n]*\n[\s\S]*?\n[ \t]*\2[ \t]*(?=\n|$)")


def problems(cmd: str, background: bool) -> list[str]:
    # Heredoc bodies are data (notes, scripts being written), not commands.
    cmd = HEREDOC.sub("", cmd)
    found = []
    if not background:
        code = QUOTED.sub("''", cmd)
        if POLL_LOOP.search(code):
            found.append(
                "Foreground polling loop. Rerun it with run_in_background: true "
                "and wait for its exit, or use Monitor for a stream of events."
            )
        for m in SLEEP.finditer(code):
            if float(m.group(1)) * UNIT[m.group(2)] >= 20:
                found.append(
                    f"Foreground sleep {m.group(1)}{m.group(2)}. Wait on a condition in a "
                    "background command instead of a fixed sleep."
                )
                break
        if re.search(r"(?:^|[;&|(\n])\s*(?:nohup\s+|\S*=\S*\s+)*(?:\S*/)?agent-wait\b", code):
            found.append(
                "agent-wait in the foreground blocks this turn. Rerun it with "
                "run_in_background: true and stop; it wakes you when it exits."
            )
        if GH_WATCH.search(code):
            found.append(
                "Foreground gh watch. Rerun it with run_in_background: true, "
                "or use agent-watch."
            )
    quoted = [q.span() for q in QUOTED.finditer(cmd)]
    for m in PROC_MATCH.finditer(cmd):
        if any(a <= m.start() < b for a, b in quoted):
            continue
        tool, pattern = m.group(1), m.group(3).strip("\"'")
        # An anchored pattern cannot match this shell, whose command line
        # starts with the shell's own path.
        if not pattern or pattern.startswith("^"):
            continue
        if "[" not in pattern:
            first = re.search(r"[A-Za-z0-9]", pattern)
            if not first:
                continue
            i = first.start()
            safe = f"{pattern[:i]}[{pattern[i]}]{pattern[i + 1:]}"
            found.append(
                f"{tool} -f '{pattern}' also matches this shell's own command "
                f"line. Bracket one character so it cannot match itself: "
                f"{tool} -f '{safe}'."
            )
        elif re.sub(r"\[(.)\]", r"\1", pattern) in cmd:
            found.append(
                f"{tool} -f '{pattern}': this command also contains the plain "
                "text it matches, so it would still match this shell. Start "
                "and stop the process in separate calls."
            )
    return found


def main() -> int:
    data = json.load(sys.stdin)
    tool_input = data.get("tool_input") or {}
    found = problems(
        tool_input.get("command") or "", bool(tool_input.get("run_in_background"))
    )
    if found:
        print("bash-guard: " + " ".join(found), file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
