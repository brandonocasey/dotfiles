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
import os
import re
import sys

POLL_LOOP = re.compile(
    r"\b(until|while)\b[^\n]*?\bdo\b(?:(?![;&\n]\s*done\b)[\s\S])*?\bsleep\b"
)
SLEEP = re.compile(r"\bsleep\s+(\d+(?:\.\d+)?)([smhd]?)\b")
UNIT = {"": 1, "s": 1, "m": 60, "h": 3600, "d": 86400}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh"}
GH_WATCH = re.compile(r"\bgh\s+(pr\s+checks\b[^\n|;&]*--watch|run\s+watch)\b")
PROC_MATCH = re.compile(
    r"\b(pkill|pgrep)\b((?:\s+-[A-Za-z]+)*?\s+-[A-Za-z]*f[A-Za-z]*(?:\s+-[A-Za-z]+)*)"
    r"(?:\s+--)?\s+(\"[^\"]*\"|'[^']*'|[^\s;|&]+)"
)


def code_only(cmd: str) -> str:
    """Blank quoted data and comments, keeping offsets.

    Quoted arguments are data (search patterns, commit messages), except the
    script given to a shell's -c flag, which stays.
    """
    out, words, word, i, n = [], [], "", 0, len(cmd)
    while i < n:
        c = cmd[i]
        if c == "\\" and i + 1 < n:
            out.append(cmd[i:i + 2])
            word += cmd[i + 1]
            i += 2
        elif c in "'\"":
            j = i + 1
            while j < n and cmd[j] != c:
                j += 2 if c == '"' and cmd[j] == "\\" else 1
            body = cmd[i + 1:j]
            script = (
                not word and len(words) >= 2
                and re.fullmatch(r"-[a-z]*c[a-z]*", words[-1])
                and os.path.basename(words[-2]) in SHELLS
            )
            out.append(c + (body if script else re.sub(r"[^\n]", " ", body)) + c)
            word += "x"
            i = j + 1
        elif c == "#" and not word:
            j = cmd.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif c.isspace() or c in ";&|()":
            if word:
                words.append(word)
                word = ""
            if c in ";&|()\n":
                words = []
            out.append(c)
            i += 1
        else:
            word += c
            out.append(c)
            i += 1
    return "".join(out)[:n]


HEREDOC = re.compile(r"<<-?[ \t]*(['\"]?)(\w+)\1[^\n]*\n[\s\S]*?\n[ \t]*\2[ \t]*(?=\n|$)")


def problems(cmd: str, background: bool) -> list[str]:
    # Heredoc bodies are data (notes, scripts being written), not commands.
    cmd = HEREDOC.sub("", cmd)
    found = []
    code = code_only(cmd)
    if not background:
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
    for m in PROC_MATCH.finditer(cmd):
        if code[m.start()] != cmd[m.start()]:
            continue  # inside quoted data or a comment
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
