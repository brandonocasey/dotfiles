#!/usr/bin/env python3
"""Codex PreToolUse guard for force pushes.

~/.codex/rules/guard.rules prompts for `git push <force flag> ...`, but Codex
matches rules only against plain commands with the flag right after `git push`.
Codex already prompts for `rm` with a force flag in any form. This hook allows
a force push only as one lone plain command in that form, and denies any other
command whose text looks like a force push, quoted text and heredocs included.
`--mirror` counts as a force flag: a mirror push force-updates and deletes
remote refs without one (git-push(1)).
"""
import json
import re
import shlex
import subprocess
import sys

FORCE = {"--force", "-f", "--force-with-lease", "--force-if-includes", "--mirror"}
# Characters that stop Codex from treating a script as plain commands.
NOT_PLAIN = re.compile(r"[\n$`<>()\\#{}*?\[\]~^;&|'\"]|(^|\s)=")
FORCE_ARG = re.compile(
    r"(^|[\s\"'=(])(--force(-with-lease|-if-includes)?(=\S*)?|--mirror|-[a-zA-Z]*f[a-zA-Z]*|\+\S+)(?=$|[\s\"');|&`<>])"
)
REASON = (
    "Codex rules only see a force push as one lone plain command with the force "
    "flag right after `git push`. Rerun it by itself, not chained, with no "
    "variables, quotes, substitutions, redirects, or subshells, for example "
    "`git push --force-if-includes --force-with-lease=<branch>:<sha> <remote> <refspec>`. "
    "Keep any lease. The user is then asked to approve it. If the text only "
    "mentions a force push (a message or note), write it with a file edit instead."
)


def force_aliases():
    """Git aliases that expand to a force push, such as `pushf`."""
    try:
        out = subprocess.run(
            ["git", "config", "--get-regexp", r"^alias\."],
            capture_output=True, text=True, timeout=3,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return []
    names = []
    for line in out.splitlines():
        name, _, value = line.partition(" ")
        if re.search(r"\bpush\b", value) and FORCE_ARG.search(value):
            names.append(re.escape(name[len("alias."):]))
    return names


def looks_like_force_push(text):
    aliases = force_aliases()
    verbs = "|".join(["push"] + aliases)
    pattern = re.compile(r"\bgit\b(.*?)(?<![\w/.-])(%s)(?=\s|$)" % verbs)
    for line in text.replace("\\\n", " ").splitlines():
        for m in pattern.finditer(line):
            if m.group(2) != "push":
                return True
            end = command_end(line, m.end())
            if FORCE_ARG.search(line, m.end(), end):
                return True
    return False


def command_end(line, start):
    """Index of the first ; & or | outside quotes at or after start."""
    quote = None
    for i in range(start, len(line)):
        ch = line[i]
        if quote:
            if ch == quote:
                quote = None
        elif ch in "'\"":
            quote = ch
        elif ch in ";&|":
            return i
    return len(line)


def lone_prompted_push(command):
    """True for one plain `git push <force flag> ...` that guard.rules prompts for."""
    command = command.strip()
    if NOT_PLAIN.search(command):
        return False
    words = command.split()
    return words[:2] == ["git", "push"] and len(words) > 2 and words[2] in FORCE


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return 0
    command = (data.get("tool_input") or {}).get("command")
    if isinstance(command, list):
        command = " ".join(shlex.quote(str(w)) for w in command)
    if not isinstance(command, str) or "git" not in command:
        return 0
    if looks_like_force_push(command) and not lone_prompted_push(command):
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": REASON,
        }}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
