#!/usr/bin/env python3
"""PreToolUse guard for Bash. Blocks patterns that waste sessions.

- Foreground polling: until/while/for loops that sleep, sleeps of 20s or more in all,
  sleeps of 10s or more followed by a log or file check, and gh watch commands. They hit the 10-minute tool cap and leave the context
  idle while its cache expires. Background runs pass.
- Sub-agent foreground calls with a timeout over 4.5 minutes. A sub-agent's cache
  lasts 5 minutes, so a longer call rewrites its whole context when it returns.
- pkill -f / pgrep -f with a plain pattern. The pattern also appears in this
  shell's own command line, so pkill kills its own shell (exit 144) and pgrep
  always finds a match.
- pkill, killall, or pgrep fed to kill, by a name or pattern, unless an option
  such as -P or -F limits it. It also stops other sessions' processes, such as
  claude -p runs whose prompt holds the text.
- Unquoted words that start with `=`. The Bash tool runs zsh, which expands
  `=foo` to a path, so `echo ===` fails with "= not found".
- A trailing echo or printf of `$?`. The Bash tool already reports the exit code.
- Headless claude (-p/--print) with --tools but no ToolSearch. Every connector
  tool is then sent in full, about 600k tokens per call.
- Headless claude inside a handoff session (AGENT_HANDOFF=1). The session reads
  the same rules as its parent, so it would hand the task off again, and again.

When every problem has a safe fix, the hook fixes the call instead of blocking it,
which saves the model a retry: it moves waits and polls to the background, quotes
`=` words, drops the `$?` echo, brackets the self-matching pattern, and adds
ToolSearch. It returns the fixed input as updatedInput with no permission
decision, so permission rules and auto mode still check the fixed command, and
a note tells the model what changed. Kills by name and claude -p in a handoff
session have no safe fix.

Exit 2 cancels the call and shows the message to the model.
"""

import json
import os
import re
import shlex
import signal
import sys
from typing import NamedTuple


class Problem(NamedTuple):
    message: str
    # A safe fix: (start, end, text) replacements in the command, None when only
    # the model can fix it, and whether running it in the background fixes it.
    edits: list[tuple[int, int, str]] | None = None
    background: bool = False
    note: str = ""


BACKGROUND_NOTE = ("It now runs in the background, so stop and wait for its exit "
                   "notification instead of polling.")

POLL_LOOP = re.compile(
    r"(?:^|[;&|({\n'\"]|\b(?:do|then|else)\b)\s*(until|while|for)\b"
    r"(?:(?!\bdone\b)[\s\S])*?\bdo\b(?:(?![;&\n]\s*done\b)[\s\S])*?\bsleep\b"
)
SLEEP = re.compile(r"\bsleep\s+(\d+(?:\.\d+)?)([smhd]?)\b")
UNIT = {"": 1, "s": 1, "m": 60, "h": 3600, "d": 86400}
SUBAGENT_MAX_MS = 270_000
SHELLS = {"sh", "bash", "zsh", "dash", "ksh"}
GH_WATCH = re.compile(r"\bgh\s+(pr\s+checks\b[^\n|;&]*--watch|run\s+watch)\b")
PROC_TOOL = re.compile(r"\b(pkill|pgrep)\b")
# Options that take a value, so the next word is not the pattern.
PROC_ARG_OPTS = {"--signal", "--pidfile", "--ns", "--nslist", "--euid", "--uid",
                 "--group", "--pgroup", "--parent", "--session", "--terminal",
                 "--delimiter", "--older", "--runstates", "--cgroup", "--queue"}
PROC_ARG_LETTERS = "uUgGPstFdOrq"  # short options that take a value (procps-ng 4)
SIGNALS = {s.name.removeprefix("SIG") for s in signal.Signals}
# Options that tie pkill to known processes: a parent, process group, session, terminal or PID file.
PROC_SCOPE_OPTS = {"--parent", "--pgroup", "--session", "--terminal", "--pidfile"}
PROC_SCOPE_LETTERS = "PgstF"
# Linux procps uses GNU getopt, which also reads options after the pattern. macOS uses BSD
# getopt, which reads them as more patterns: there `pkill -f x -P 1` also kills "-P" and "1".
OPTIONS_AFTER_PATTERN = sys.platform.startswith("linux")


def proc_args(words: list[str]) -> tuple[str | None, bool, bool, list[str]]:
    """A pkill/pgrep's pattern, whether it uses -f, whether an option scopes it, and
    the later words this system reads as more patterns, not as options."""
    full = scoped = False
    pattern, i = None, 0
    while i < len(words):
        w = words[i]
        if w == "--":
            if pattern is None and i + 1 < len(words):
                pattern, i = words[i + 1], i + 1
            break
        name = w.split("=", 1)[0]  # --parent=123 as well as --parent 123
        if name in PROC_ARG_OPTS:
            scoped = scoped or name in PROC_SCOPE_OPTS
            i += 1 if "=" in w else 2
            continue
        if w[1:].removeprefix("SIG") in SIGNALS or re.fullmatch(r"-\d+", w):
            pass  # a signal such as -HUP or -9, not option letters
        elif re.match(r"-[A-Za-z]", w):
            # Letters up to the first that takes a value; the rest of the word is
            # that value (-uroot, -P123), or else the next word is (-u root, -fu root).
            for j, c in enumerate(w[1:], 1):
                full = full or c == "f"
                if c in PROC_ARG_LETTERS:
                    scoped = scoped or c in PROC_SCOPE_LETTERS
                    if j == len(w) - 1:
                        i += 1  # skip the value in the next word
                    break
        elif w == "--full":
            full = True
        elif not w.startswith("-"):
            if pattern is not None:
                break  # a second pattern, which procps rejects
            pattern = w
            if not OPTIONS_AFTER_PATTERN:
                break
        i += 1
    extra = [] if OPTIONS_AFTER_PATTERN or pattern is None else words[i + 1:]
    return pattern, full, scoped, extra


def proc_pattern(words: list[str]) -> str | None:
    """The pattern of a pkill/pgrep that uses -f, or None."""
    pattern, full, _, _ = proc_args(words)
    return pattern if full else None


def code_only(cmd: str, keep_scripts: bool = True, keep_double: bool = False) -> str:
    """Blank quoted data and comments, keeping offsets.

    Quoted arguments are data (search patterns, commit messages), except the
    script given to a shell's -c flag, which stays when keep_scripts is set.
    keep_double keeps double-quoted text, where variables still expand.
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
            keep = script or (keep_double and c == '"')
            out.append(c + (body if keep else re.sub(r"[^\n]", " ", body)) + c)
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


ZSH_EQUALS = re.compile(r"(?<![^\s;&|(])=[^\s;&|()]")
# [[ ... ]], (( ... )) and $(( ... )) keep == as a comparison operator.
COMPARISONS = re.compile(r"\[\[[\s\S]*?\]\]|\$?\(\([\s\S]*?\)\)")
CMD_START = r"(?:^|[;&|(\n{]|\b(?:then|do|else)\b)\s*(?:\S*=\S*\s+)*(?:\S*/)?"
# The script given to a shell's -c flag starts a command too.
SCRIPT_START = r"(?<!\S)-[A-Za-z]*c[A-Za-z]*\s+['\"]\s*(?:\S*=\S*\s+)*(?:\S*/)?"
# Commands that run the next word as a command, with their options and durations.
WRAPPERS = (r"(?:(?:nohup|setsid|exec|command|env|nice|time|g?timeout)(?:\s+(?:-\S+|\d\S*))*"
            r"\s+(?:\S*=\S*\s+)*(?:\S*/)?)*")
SEGMENT_END = re.compile(r"[;|]|(?<![<>])&(?!>)|(?<!\\)\n")
PRINT_CMD = re.compile(CMD_START + r"(?:builtin\s+|command\s+)?(?:echo|printf)\b")
# Commands that check a log or file, as a sleep-then-check poll does. A pipe
# does not start one (`curl ... | head` reads no file), and a path such as
# ./test.sh is not the test builtin.
READ_CMD = re.compile(
    r"(?:^|\|\||[;&(\n{]|\b(?:then|do|else|elif|if)\b|!)\s*(?:\S*=\S*\s+)*"
    r"(?:(?:tail|cat|head|less|ls|test|rg|grep|wc|stat|sed|awk|jq)(?=\s|$)|\[\[?\s)"
)
# > or >> to a file, not a descriptor duplication such as >&2.
FILE_REDIRECT = re.compile(r">>?(?!&)\s*\S")
CLAUDE_CMD = re.compile(f"(?:{CMD_START}|{SCRIPT_START}){WRAPPERS}claude(?:-two)?\\b")
# -p or --print, also --print=VALUE and grouped short flags such as -pc, so a reworded launch still matches.
# Any character that cannot continue a flag name ends it: -p), -p<f, -p"x", -p`x`.
HEADLESS_FLAG = re.compile(r"(?:^|\s)(?:--print(?:=\S*)?|-[A-Za-z0-9]*p[A-Za-z0-9]*)(?![\w=-])")
TOOLS_FLAG = re.compile(r"(?<!\S)--tools(?:=|(?=\s|$))")
# pkill, pgrep and killall where a command starts, also inside $(...) and `...`.
KILL_CMD = re.compile(f"(?:{CMD_START}|`|{SCRIPT_START}){WRAPPERS}(?:(?:sudo|xargs)\\s+(?:-\\S+\\s+)*)*(pkill|pgrep|killall)\\b")
# pgrep output fed to kill: `pgrep ... | xargs kill` or `kill $(pgrep ...)`. kill -0 only checks.
KILL_AFTER = re.compile(r"[^;&\n|]*\|\s*xargs\b[^;&\n|]*\bkill\b(?!\s+-0\b)")
KILL_BEFORE = re.compile(r"\bkill\b(?!\s+-0\b)[^;&\n|]*(?:\$\(|`)\s*$")


def segments(cmd: str, code: str, start: re.Pattern) -> list[tuple[int, str, str]]:
    """The text after each command that start matches, up to its end.

    code is cmd with quoted data blanked, so quoted separators do not end a
    command. Each item gives the text's offset in cmd, the original text and
    its code, so flags are found in code and their quoted values read from the
    original.
    """
    out = []
    for m in start.finditer(code):
        end = SEGMENT_END.search(code, m.end())
        stop = end.start() if end else len(cmd)
        out.append((m.end(), cmd[m.end():stop], code[m.end():stop]))
    return out


def tool_names(rest: str) -> list[str]:
    """The names given to --tools: every word up to the next option."""
    try:
        words = shlex.split(rest)
    except ValueError:
        words = rest.split()
    names = []
    for w in words:
        if w.startswith("-"):
            break
        names += re.split(r"[\s,]+", w)
    return names


def broad_kills(cmd: str, code: str) -> dict[int, str]:
    """Kills by a name or pattern that also reach other sessions' processes,
    keyed by where each pkill, pgrep or killall starts.

    No pattern is safe: paths are shared (a main checkout, $HOME) and a regex
    alternation such as 'x|own/path' matches beyond its own part.
    """
    pick = ("List them with pgrep -fl '[n]ame', check they are yours, then kill "
            "them by number in a separate call.")
    found = {}
    for m in KILL_CMD.finditer(code):
        tool = m.group(1)
        rest = re.split(r"[;&|\n)`]", code[m.end():], maxsplit=1)[0]
        try:
            words = shlex.split(cmd[m.end():m.end() + len(rest)])
        except ValueError:
            words = rest.split()
        if tool == "killall":
            if any(not w.startswith("-") for w in words):
                found[m.start(1)] = (
                    f"killall {' '.join(words)} stops matching processes in every session. {pick}"
                )
            continue
        if tool == "pgrep" and not (KILL_AFTER.match(code, m.end()) or KILL_BEFORE.search(code, 0, m.start(1))):
            continue
        pattern, _, scoped, extra = proc_args(words)
        if not pattern or scoped:
            continue
        late = (" On this system, words after the pattern are more patterns, not options: "
                "put options such as -P before it." if any(w.startswith("-") for w in extra) else "")
        found[m.start(1)] = (
            f"{'pkill' if tool == 'pkill' else 'kill of pgrep'} '{pattern}' stops every matching "
            "process in every session: other tasks' tests and servers, and claude -p runs whose "
            "prompt holds that text. Kill the PID you saved when you started the process "
            f"(kill $PID, or pkill -F <pidfile>). {pick}{late}"
        )
    return found


def blank(m: re.Match) -> str:
    """The match as spaces, keeping newlines, so offsets stay the same."""
    return re.sub(r"[^\n]", " ", m.group())


# Where an unquoted = word ends; a quote, backslash or $ in it leaves it to the model.
EQUALS_WORD = re.compile(r"[^\s;&|()<>]*")
GAP = re.compile(r"(?:\s|\\\n)*")
PLAIN_WORD = re.compile(r"[^\s;&|()<>'\"`$\\]*")


def span_end(pattern: re.Pattern, text: str, pos: int) -> int:
    """Where a match of pattern, which may be empty, ends from pos."""
    m = pattern.match(text, pos)
    return m.end() if m else pos


def equals_edits(cmd: str, analysed: str) -> list[tuple[int, int, str]] | None:
    """Single-quote each unquoted word that starts with =, or None when one cannot be."""
    edits = []
    for m in ZSH_EQUALS.finditer(analysed):
        end = span_end(EQUALS_WORD, cmd, m.start())
        word = cmd[m.start():end]
        if any(c in word for c in "'\"\\$`"):
            return None
        edits.append((m.start(), end, f"'{word}'"))
    return edits


def drop_status_echo(original: str, cmd: str, code: str, bare: str, start: int) -> list[tuple[int, int, str]] | None:
    """Remove a trailing echo of $? that starts after the separator at start.

    Only after ;, a newline, && or ||: dropping it after & would bring the job
    before it into the foreground, and after | would leave a dangling pipe.
    Not inside a quoted script, group or substitution, whose closing ) } ` or
    quote the cut would remove, nor across a heredoc, which cmd holds blanked.
    """
    sep = cmd[start]
    if not (sep in ";\n" or (sep in "&|" and start > 0 and cmd[start - 1] == sep)):
        return None
    if bare[start] != cmd[start] or any(c in code[start:] for c in ")}`"):
        return None
    cut = len(cmd[:start].rstrip(" \t\n;&|"))
    if not cut or original[cut:start] != cmd[cut:start]:
        return None
    return [(cut, len(cmd), "")]


def drop_trailing_amp(code: str) -> list[tuple[int, int, str]]:
    """Remove a final & so run_in_background tracks the job itself, not a shell
    that exits as soon as it has forked the job."""
    end = len(code.rstrip())
    if end and code[end - 1] == "&" and code[end - 2:end] != "&&":
        return [(len(code[:end - 1].rstrip()), end, "")]
    return []


def add_toolsearch(cmd: str, pos: int) -> list[tuple[int, int, str]] | None:
    """Append ToolSearch to the --tools value that starts at or after pos."""
    if cmd[pos:pos + 1] == "=":
        pos += 1
    else:
        pos = span_end(GAP, cmd, pos)
    if cmd[pos:pos + 1] in ("'", '"'):
        close = cmd.find(cmd[pos], pos + 1)
        return [(close, close, ",ToolSearch")] if close > pos + 1 else None
    end = span_end(PLAIN_WORD, cmd, pos)
    if end == pos or cmd[pos] == "-" or (end < len(cmd) and not cmd[end].isspace() and cmd[end] not in ";&|)<>"):
        return None
    return [(end, end, ",ToolSearch")]


def bracket_edit(cmd: str, start: int, stop: int, pattern: str, safe: str) -> list[tuple[int, int, str]] | None:
    """Replace the pattern written between start and stop with its bracketed form."""
    p = re.escape(pattern)
    m = re.compile(rf"'({p})'|\"({p})\"|(?<!\S)({p})(?=$|[\s;&|)])").search(cmd, start, stop)
    if not m:
        return None
    if m.group(3) is not None:
        return None if "'" in safe else [(m.start(3), m.end(3), f"'{safe}'")]
    group = 1 if m.group(1) is not None else 2
    if group == 2 and any(c in safe for c in "\"$`\\"):
        return None
    return [(m.start(group), m.end(group), safe)]


def problems(cmd: str, background: bool) -> list[Problem]:
    # Heredoc bodies are data (notes, scripts being written), not commands.
    # Blanked, not removed, so offsets match the command that fixes edit.
    original, cmd = cmd, HEREDOC.sub(blank, cmd)
    found = []
    code = code_only(cmd)
    bare = code_only(cmd, False)
    if not background:
        # Commands ending in & run in the background, like the detached
        # `nohup setsid sh -c '...' &` form subagent-wait suggests.
        fg = foreground(code, bare)
        if POLL_LOOP.search(fg):
            found.append(Problem(
                "Foreground polling loop. Rerun it with run_in_background: true "
                "and wait for its exit, or use Monitor for a stream of events.",
                [], True, "It was a foreground polling loop."
            ))
        total = 0.0
        for m in SLEEP.finditer(fg):
            seconds = float(m.group(1)) * UNIT[m.group(2)]
            total += seconds  # chained sleeps (sleep 19; sleep 19) add up
            if total >= 20:
                found.append(Problem(
                    f"Foreground sleep {m.group(1)}{m.group(2)}"
                    f"{f' ({total:g}s in all)' if total > seconds else ''}. Wait on a "
                    "condition in a background command instead of a fixed sleep.",
                    [], True, "It slept in the foreground."
                ))
                break
            if seconds >= 10 and READ_CMD.search(fg, m.end()):
                found.append(Problem(
                    f"Sleep-then-check polling (sleep {m.group(1)}{m.group(2)}, then a read). "
                    "Wait for the job's exit notification, or run agt wait with "
                    "run_in_background: true and stop; it wakes you when it exits.",
                    [], True, "It slept, then checked a file."
                ))
                break
        # Also with a trailing &: the harness tracks only run_in_background jobs.
        if re.search(r"(?:^|[;&|(\n])\s*(?:nohup\s+|\S*=\S*\s+)*(?:\S*/)?agt\s+(?:ci\s+)?wait\b(?!\s+(?:-h|--help)(?:$|[\s;&|)]))", code):
            found.append(Problem(
                "agt wait in the foreground blocks this turn. Rerun it with "
                "run_in_background: true and stop; it wakes you when it exits.",
                drop_trailing_amp(code), True, "agt wait in the foreground blocks the turn."
            ))
        if GH_WATCH.search(fg):
            found.append(Problem(
                "Foreground gh watch. Rerun it with run_in_background: true, "
                "or run agt ci wait in the background.",
                [], True, "gh watch in the foreground blocks the turn."
            ))
    # bare also blanks sh -c and bash -c scripts, which have no = expansion.
    analysed = COMPARISONS.sub(blank, bare)
    if ZSH_EQUALS.search(analysed):
        found.append(Problem(
            "An unquoted word starting with = is a zsh path expansion "
            "(`echo ===` fails with \"= not found\"). Print separators with "
            "printf '--- %s\\n' and quote any other word that starts with =.",
            equals_edits(cmd, analysed), False,
            "Words starting with = are now single-quoted; zsh expands an unquoted =word to a path."
        ))
    # Keeps "$?", where it still expands; drops '$?' and comments.
    expanding = code_only(cmd, keep_double=True)
    for m in PRINT_CMD.finditer(code):
        end = SEGMENT_END.search(code, m.end())
        stop = end.start() if end else len(code)
        # Only a trailing echo repeats the status the tool reports. Echoes inside
        # groups or loops, or written to a file, record statuses it never shows.
        trailing = not code[stop:].strip(" \t\n;&|")
        if (
            trailing and "$?" in expanding[m.end():stop]
            and not FILE_REDIRECT.search(code[m.end():stop])
        ):
            found.append(Problem(
                "Do not print $?; the Bash tool already reports the exit code "
                "of every command.",
                drop_status_echo(original, cmd, code, bare, m.start()), False,
                "The trailing echo of $? was removed; the tool reports the exit code."
            ))
            break
    for offset, args, args_code in segments(cmd, code, CLAUDE_CMD):
        tools = TOOLS_FLAG.search(args_code)
        if not (tools and HEADLESS_FLAG.search(args_code)) or "--strict-mcp-config" in args_code:
            continue
        names = tool_names(args[tools.end():])
        if "ToolSearch" not in names and "default" not in names:
            found.append(Problem(
                "Headless claude with --tools but without ToolSearch sends every "
                "connector tool in full (about 600k tokens per call). Add "
                "ToolSearch to the --tools list, or pass --strict-mcp-config.",
                add_toolsearch(cmd, offset + tools.end()), False,
                "ToolSearch was added to --tools; without it every connector tool is sent in full."
            ))
            break
    # The handoff command sets AGENT_HANDOFF=1, and this hook runs in its session.
    if os.environ.get("AGENT_HANDOFF") == "1":
        if any(HEADLESS_FLAG.search(args_code) for _, _, args_code in segments(cmd, code, CLAUDE_CMD)):
            found.append(Problem(
                "This is a handoff session (AGENT_HANDOFF=1), so do not start another "
                "claude -p session. Run the handoff stages here, in this session."
            ))
    kills = broad_kills(cmd, code)
    for m in PROC_TOOL.finditer(cmd):
        if code[m.start()] != cmd[m.start()]:
            continue  # inside quoted data or a comment
        if m.start() in kills:
            continue  # blocked as a broad kill; a bracket alone would not make it safe
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
            # A pgrep only lists. A pkill here may be a broad kill that KILL_CMD
            # missed (after if, or sudo -u root), so only a scoped one is fixed.
            if tool == "pgrep" or proc_args(words)[2]:
                found.append(Problem(
                    f"{tool} -f '{pattern}' also matches this shell's own command "
                    f"line. Bracket one character of the pattern so it cannot match "
                    f"itself: '{safe}'.",
                    bracket_edit(cmd, m.end(), m.end() + len(rest), pattern, safe), False,
                    f"The {tool} -f pattern is now '{safe}', so it cannot match its own shell."
                ))
            else:
                found.append(Problem(
                    f"pkill -f '{pattern}' stops every matching process in every session, "
                    "and also this shell. Kill the PID you saved when you started the "
                    "process (kill $PID, or pkill -F <pidfile>)."
                ))
        elif re.sub(r"\[(.)\]", r"\1", pattern) in cmd:
            found.append(Problem(
                f"{tool} -f '{pattern}': this command also contains the plain "
                "text it matches, so it would still match this shell. Start "
                "and stop the process in separate calls."
            ))
    return found + [Problem(message) for message in kills.values()]


def fix(tool_input: dict, found: list[Problem], subagent: bool) -> tuple[dict, str] | None:
    """The fixed tool input and a note for the model, or None when a problem has no
    safe fix, edits overlap, or the fixed command still has problems."""
    if not found:
        return None
    edits = []
    for p in found:
        if p.edits is None:
            return None
        edits += p.edits
    edits.sort()
    cmd = tool_input.get("command") or ""
    if any(a[1] > b[0] for a, b in zip(edits, edits[1:])):
        return None
    for start, end, text in reversed(edits):
        cmd = cmd[:start] + text + cmd[end:]
    background = bool(tool_input.get("run_in_background")) or any(p.background for p in found)
    fixed = dict(tool_input, command=cmd, run_in_background=background)
    if problems(cmd, background) or (subagent and long_subagent_call(fixed)):
        return None
    notes = [p.note for p in found]
    if background and not tool_input.get("run_in_background"):
        notes.append(BACKGROUND_NOTE)
    if edits:
        notes.append(f"Command run: {cmd}")
    return fixed, "bash-guard changed this Bash call before it ran. " + " ".join(dict.fromkeys(notes))


def long_subagent_call(tool_input: dict) -> list[Problem]:
    """A sub-agent foreground call allowed to outlast its 5-minute cache."""
    if tool_input.get("run_in_background"):
        return []
    try:
        limit = float(tool_input.get("timeout") or 0)
    except (TypeError, ValueError):
        return []
    if limit <= SUBAGENT_MAX_MS:
        return []
    return [Problem(
        f"Sub-agent foreground call with a {limit / 60000:.1f}-minute timeout. Your "
        "prompt cache expires after 5 idle minutes, so a longer call rewrites your "
        f"whole context when it returns. Use a timeout of {SUBAGENT_MAX_MS} or less, "
        "or rerun it with run_in_background: true and stop.",
        [], True,
        f"Its {limit / 60000:.1f}-minute timeout would outlast your 5-minute prompt cache."
    )]


def main() -> int:
    data = json.load(sys.stdin)
    tool_input = data.get("tool_input") or {}
    found = problems(
        tool_input.get("command") or "", bool(tool_input.get("run_in_background"))
    )
    subagent = bool(data.get("agent_id"))
    if subagent:
        found += long_subagent_call(tool_input)
    if not found:
        return 0
    fixed = fix(tool_input, found, subagent)
    if fixed:
        updated, note = fixed
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse", "updatedInput": updated, "additionalContext": note,
        }}))
        return 0
    print("bash-guard: " + " ".join(p.message for p in found), file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
