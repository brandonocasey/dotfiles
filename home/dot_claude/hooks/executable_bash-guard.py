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
import shlex
import signal
import sys

POLL_LOOP = re.compile(
    r"(?:^|[;&|({\n'\"]|\b(?:do|then|else)\b)\s*(until|while)\b"
    r"(?:(?!\bdone\b)[\s\S])*?\bdo\b(?:(?![;&\n]\s*done\b)[\s\S])*?\bsleep\b"
)
SLEEP = re.compile(r"\bsleep\s+(\d+(?:\.\d+)?)([smhd]?)\b")
UNIT = {"": 1, "s": 1, "m": 60, "h": 3600, "d": 86400}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh"}
GH_WATCH = re.compile(r"\bgh\s+(pr\s+checks\b[^\n|;&]*--watch|run\s+watch)\b")
PROC_TOOL = re.compile(r"\b(pkill|pgrep)\b")
# Options that take a value, so the next word is not the pattern.
PROC_ARG_OPTS = {"--signal", "--pidfile", "--ns", "--nslist", "--euid", "--uid",
                 "--group", "--pgroup", "--parent", "--session", "--terminal",
                 "--delimiter", "--older", "--runstates", "--cgroup", "--queue"}
PROC_ARG_LETTERS = "uUgGPstFdOrq"  # short options that take a value (procps-ng 4)
SIGNALS = {s.name.removeprefix("SIG") for s in signal.Signals}


def proc_pattern(words: list[str]) -> str | None:
    """The pattern of a pkill/pgrep that uses -f, or None."""
    full, i = False, 0
    while i < len(words):
        w = words[i]
        if w == "--":
            return words[i + 1] if full and i + 1 < len(words) else None
        if w in PROC_ARG_OPTS:
            i += 2
            continue
        if w[1:].removeprefix("SIG") in SIGNALS or re.fullmatch(r"-\d+", w):
            pass  # a signal such as -HUP or -9, not option letters
        elif re.fullmatch(r"-[A-Za-z]+", w):
            full = full or "f" in w[1:]
            if w[-1] in PROC_ARG_LETTERS:  # -u root, -fu root: next word is a value
                i += 2
                continue
        elif w == "--full":
            full = True
        elif not w.startswith("-"):
            return w if full else None
        i += 1
    return None


def code_only(cmd: str, keep_scripts: bool = True) -> str:
    """Blank quoted data and comments, keeping offsets.

    Quoted arguments are data (search patterns, commit messages), except the
    script given to a shell's -c flag, which stays when keep_scripts is set.
    """
    out, words, word, i, n = [], [], "", 0, len(cmd)
    while i < n:
        c = cmd[i]
        if c == "\\" and i + 1 < n:
            out.append(cmd[i:i + 2])
            if cmd[i + 1] != "\n":  # an escaped newline only joins lines
                word += cmd[i + 1]
            i += 2
        elif c in "'\"":
            # Backslash escapes work in "..." and in $'...'.
            escapes = c == '"' or (i > 0 and cmd[i - 1] == "$")
            j = i + 1
            while j < n and cmd[j] != c:
                j += 2 if escapes and cmd[j] == "\\" else 1
            body = cmd[i + 1:j]
            script = (
                keep_scripts and not word and len(words) >= 2
                and re.fullmatch(r"-[A-Za-z]*c[A-Za-z]*", words[-1])
                and any(os.path.basename(w) in SHELLS for w in words[:-1])
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


KEYWORDS = {"do": "done", "if": "fi", "case": "esac"}
LEADS = {"do", "then", "else", "elif", "if", "while", "until", "!", "time"}
SHELL_TOKEN = re.compile(
    r"&&|\|\||;;|[;&|(){}\n]|(?:\d*[<>]&\d*-?|&>>?|[^\s;&|(){}])+"
)


def foreground(code: str, bare: str) -> str:
    """code with top-level backgrounded commands (`cmd &`) blanked.

    bare is code with every quoted string blanked, so quoted separators do
    not count. A `&` inside a loop or group leaves it: the loop still runs
    in the foreground.
    """
    out, stack, start, cmd_pos = list(code), [], 0, True
    for m in SHELL_TOKEN.finditer(bare):
        tok = m.group()
        if tok in ("(", "{"):
            if not (tok == "(" and stack and stack[-1] == "case"):
                stack.append(tok)
            cmd_pos = True
        elif tok in (")", "}"):
            if stack and stack[-1] == {")": "(", "}": "{"}[tok]:
                stack.pop()
            cmd_pos = True  # also after a case pattern such as `a)`
        elif tok in (";", "\n", "&", ";;", "&&", "||", "|"):
            if not stack and tok in (";", "\n", "&"):
                if tok == "&":
                    for k in range(start, m.start()):
                        out[k] = "\n" if out[k] == "\n" else " "
                start = m.end()
            cmd_pos = True
        else:
            if cmd_pos and tok in KEYWORDS:
                stack.append(tok)
            elif cmd_pos and stack and KEYWORDS.get(stack[-1]) == tok:
                stack.pop()
            cmd_pos = tok in LEADS
    return "".join(out)


HEREDOC = re.compile(r"<<-?[ \t]*(['\"]?)(\w+)\1[^\n]*\n[\s\S]*?\n[ \t]*\2[ \t]*(?=\n|$)")


def problems(cmd: str, background: bool) -> list[str]:
    # Heredoc bodies are data (notes, scripts being written), not commands.
    cmd = HEREDOC.sub("", cmd)
    found = []
    code = code_only(cmd)
    if not background:
        # Commands ending in & run in the background, like the detached
        # `nohup setsid sh -c '...' &` form subagent-wait suggests.
        fg = foreground(code, code_only(cmd, False))
        if POLL_LOOP.search(fg):
            found.append(
                "Foreground polling loop. Rerun it with run_in_background: true "
                "and wait for its exit, or use Monitor for a stream of events."
            )
        for m in SLEEP.finditer(fg):
            if float(m.group(1)) * UNIT[m.group(2)] >= 20:
                found.append(
                    f"Foreground sleep {m.group(1)}{m.group(2)}. Wait on a condition in a "
                    "background command instead of a fixed sleep."
                )
                break
        # Also with a trailing &: the harness tracks only run_in_background jobs.
        if re.search(r"(?:^|[;&|(\n])\s*(?:nohup\s+|\S*=\S*\s+)*(?:\S*/)?agent-wait\b", code):
            found.append(
                "agent-wait in the foreground blocks this turn. Rerun it with "
                "run_in_background: true and stop; it wakes you when it exits."
            )
        if GH_WATCH.search(fg):
            found.append(
                "Foreground gh watch. Rerun it with run_in_background: true, "
                "or use agent-watch."
            )
    for m in PROC_TOOL.finditer(cmd):
        if code[m.start()] != cmd[m.start()]:
            continue  # inside quoted data or a comment
        tool = m.group(1)
        rest = re.split(r"[;&|\n)]", code[m.end():], maxsplit=1)[0]
        try:
            words = shlex.split(cmd[m.end():m.end() + len(rest)])
        except ValueError:
            words = rest.split()
        pattern = (proc_pattern(words) or "").strip("\"'")
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
