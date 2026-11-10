#!/usr/bin/env python3
"""Deny edits whose ~/.claude/rules files may be missing from the agent's context, until it reads those rules whole or
retries a denied edit.

Claude Code skips rules for files outside the working folder, loads a new file's rules only with its first write, and
does not reload rules after a compaction.
"""

# Hooks run on the python3 on PATH, which can be Apple's Python 3.9.
from __future__ import annotations

import contextlib
import fcntl
import hashlib
import json
import os
import re
import stat
import sys
import tempfile
import time
from pathlib import Path, PurePosixPath
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from typing import TypeGuard  # Python 3.10+

EDIT_TOOLS = ("Edit", "Write", "MultiEdit")
STATE_MAX_AGE_SECONDS = 7 * 24 * 3600
NAME_PART = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*")
SCRATCH_PARTS = (".cache", "agents", "scratch")
LIST_ITEM = re.compile(r"\s*-\s+(.*?)\s*")
PATHS_KEY = re.compile(r"paths\s*:\s*(.*?)\s*")
QUOTES = "\"'"


def home() -> Path:
    return Path(os.path.expanduser("~"))


def state_dir() -> Path:
    base = os.environ.get("XDG_STATE_HOME") or home() / ".local/state"
    return Path(base) / "agents/rule-gate"


def name_part(value: object) -> str | None:
    """A session or agent id usable as a file name and as a space-free record field."""
    return value if isinstance(value, str) and NAME_PART.fullmatch(value) else None


def agent_ids(data: dict) -> tuple[str | None, str | None]:
    """The session id and the agent key (`main` for the main session) of a hook input, each None when unusable."""
    return name_part(data.get("session_id")), name_part(data.get("agent_id") or "main")


def valid_path(value: object) -> TypeGuard[str]:
    """Whether the value is a non-empty string that the OS accepts as a path."""
    if not isinstance(value, str) or not value or "\0" in value:
        return False
    try:
        os.fsencode(value)
    except UnicodeEncodeError:
        return False
    return True


@contextlib.contextmanager
def open_locked(path: Path):
    """Yield the state file under an exclusive lock, reopening it when a save replaced it while this process waited."""
    while True:
        with open(path, "a+b") as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            try:
                current = os.path.samestat(os.fstat(f.fileno()), os.stat(path))
            except FileNotFoundError:
                current = False
            if current:
                yield f
                return


@contextlib.contextmanager
def locked_records(path: Path):
    """Yield the (key, rule path) records of a state file under an exclusive lock, and save changes.

    A key is an agent id for a rule in that agent's context, `<agent id>/<file digest>/batch` for edits of that file
    denied in the agent's current tool batch, or `<agent id>/<file digest>` once that batch has ended.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    with open_locked(path) as f:
        # Bytes split only on \n and round-trip undecodable names.
        f.seek(0)
        lines = f.read().decode("utf-8", "surrogateescape").split("\n")
        records = {tuple(line.split(" ", 1)) for line in lines if " " in line}
        before = set(records)
        yield records
        if records != before:
            data = "".join(f"{key} {rule}\n" for key, rule in sorted(records)).encode("utf-8", "surrogateescape")
            # A dot-led name is never a session id. Replacing the file keeps the old records if the write fails.
            fd, temp = tempfile.mkstemp(dir=path.parent, prefix=".")
            try:
                with os.fdopen(fd, "wb") as out:
                    out.write(data)
                os.replace(temp, path)
            except BaseException:
                os.unlink(temp)
                raise


def prune(directory: Path) -> None:
    cutoff = time.time() - STATE_MAX_AGE_SECONDS
    try:
        entries = list(os.scandir(directory))
    except OSError:
        return
    for entry in entries:
        try:
            if entry.is_file(follow_symlinks=False) and entry.stat().st_mtime < cutoff:
                os.unlink(entry.path)
        except OSError:
            continue


def char_class(body: str) -> str:
    """The regex for the inside of a `[...]` class: `!` or `^` negates, `a-z` is a range, and a negated class never
    matches `/`."""
    negate = body[:1] in ("!", "^")
    chars, members, i = body[negate:], [], 0
    while i < len(chars):
        if chars[i + 1:i + 2] == "-" and i + 2 < len(chars):
            members.append(f"{re.escape(chars[i])}-{re.escape(chars[i + 2])}")
            i += 3
        else:
            members.append(re.escape(chars[i]))
            i += 1
    return f"[{'^/' if negate else ''}{''.join(members)}]"


def class_end(glob: str, start: int) -> int:
    """The index of the `]` closing the `[` at start, or -1 when it is unclosed."""
    i = start + 1 + (glob[start + 1:start + 2] in ("!", "^"))
    return glob.find("]", i + (glob[i:i + 1] == "]"))


def translate(glob: str) -> str:
    """The regex source for a glob: `**` spans whole segments, `*` and `?` stay in a segment, `{a,b}` nests."""
    depth, balanced = 0, True
    for ch in glob:
        depth += (ch == "{") - (ch == "}")
        balanced = balanced and depth >= 0
    balanced = balanced and depth == 0
    out, depth, i = [], 0, 0
    while i < len(glob):
        ch = glob[i]
        at_segment_start = i == 0 or glob[i - 1] in "/{,"
        if glob.startswith("**/", i) and at_segment_start:
            out.append("(?:[^/]*/)*")
            i += 3
            continue
        if glob.startswith("**", i) and at_segment_start and (i + 2 == len(glob) or glob[i + 2] in "},"):
            out.append(".*")
            i += 2
            continue
        end = class_end(glob, i) if ch == "[" else -1
        if end != -1:
            out.append(char_class(glob[i + 1:end]))
            i = end + 1
            continue
        if ch == "*":
            out.append("[^/]*")
        elif ch == "?":
            out.append("[^/]")
        elif balanced and ch == "{":
            out.append("(?:")
            depth += 1
        elif balanced and ch == "}":
            out.append(")")
            depth -= 1
        elif balanced and ch == "," and depth:
            out.append("|")
        else:
            out.append(re.escape(ch))
        i += 1
    return "".join(out)


def glob_regex(glob: str) -> re.Pattern:
    """Compile a rule glob as gitignore reads it: without a slash (or with only a trailing one) it matches at any depth.

    A leading slash anchors it to the base, and also lets it match an absolute path.
    """
    glob = glob.removesuffix("/")
    if glob.startswith("/"):
        return re.compile(f"(?:{translate(glob[1:])})|(?:{translate(glob)})")
    return re.compile(("" if "/" in glob else "(?:[^/]*/)*") + translate(glob))


def glob_matches(glob: str, paths: list[str]) -> bool:
    try:
        regex = glob_regex(glob)
    except re.error:
        return False
    return any(regex.fullmatch(p) for p in paths)


def candidates(match_path: str) -> list[str]:
    """The path and each ancestor directory: a glob matching a directory covers everything under it."""
    parents = [p.as_posix() for p in PurePosixPath(match_path).parents if p.as_posix() not in (".", "/")]
    return [match_path, *parents]


def unquote(value: str) -> str:
    quoted = len(value) >= 2 and value[0] == value[-1] and value[0] in QUOTES and value.count(value[0]) == 2
    return value[1:-1] if quoted else value


def split_commas(value: str) -> list[str]:
    """Split on commas outside quotes, braces, and brackets."""
    parts, depth, quote, start = [], 0, "", 0
    for i, ch in enumerate(value):
        if quote:
            quote = "" if ch == quote else quote
        elif ch in QUOTES:
            quote = ch
        else:
            depth += (ch in "{[") - (ch in "}]")
            if ch == "," and depth <= 0:
                parts.append(value[start:i])
                start = i + 1
    return [*parts, value[start:]]


def strip_comment(value: str) -> str:
    """The value without a YAML comment: a `#` outside quotes that starts the value or follows a space."""
    quote = ""
    for i, ch in enumerate(value):
        if quote:
            quote = "" if ch == quote else quote
        elif ch in QUOTES:
            quote = ch
        elif ch == "#" and (i == 0 or value[i - 1] in " \t"):
            return value[:i].rstrip()
    return value


def inline_globs(value: str) -> list[str]:
    """The globs of an inline `paths:` value: a flow list or one comma-separated string."""
    if value.startswith("[") and value.endswith("]"):
        value = value[1:-1]
    return [g for g in (unquote(p.strip()) for p in split_commas(unquote(value))) if g]


def open_nonblocking(path: str, flags: int) -> int:
    """Open without waiting for a writer, which a FIFO would block on forever."""
    return os.open(path, flags | os.O_NONBLOCK)


@contextlib.contextmanager
def open_rule(rule: str | os.PathLike[str]):
    """Yield the rule's text file, or None when it is not a regular file."""
    with open(rule, encoding="utf-8-sig", errors="replace", opener=open_nonblocking) as f:
        yield f if stat.S_ISREG(os.fstat(f.fileno()).st_mode) else None


def rule_globs(rule: Path) -> list[str]:
    """The globs of a rule's frontmatter `paths:`: a block list, a flow list on one or more lines, or one string.

    Like Claude Code, read no frontmatter when the closing `---` is missing. A rule that is not a regular file has none.
    """
    globs = []
    with open_rule(rule) as f:
        if f is None or f.readline().strip() != "---":
            return []
        in_paths, flow = False, ""
        for line in f:
            line = line.rstrip("\n")
            if line.strip() == "---":
                return globs
            if flow:
                flow += " " + strip_comment(line.strip())
                if flow.endswith("]"):
                    globs += inline_globs(flow)
                    flow = ""
                continue
            key = PATHS_KEY.fullmatch(line)
            if key:
                inline = strip_comment(key.group(1))
                in_paths = not inline
                if inline.startswith("[") and not inline.endswith("]"):
                    flow = inline
                else:
                    globs += inline_globs(inline)
                continue
            item = LIST_ITEM.fullmatch(line) if in_paths else None
            if item:
                if glob := unquote(strip_comment(item.group(1))):
                    globs.append(glob)
            elif line.strip() and not line.lstrip().startswith("#"):
                in_paths = False
    return []


def rule_files(directory: Path) -> list[Path]:
    """The `.md` files under the directory, following symlinks and visiting each real directory once."""
    found, seen = [], {os.path.realpath(directory)}
    for root, dirs, files in os.walk(directory, followlinks=True):
        unseen = []
        for d in sorted(dirs):
            real = os.path.realpath(os.path.join(root, d))
            if real not in seen:
                seen.add(real)
                unseen.append(d)
        dirs[:] = unseen
        found += [Path(root, f) for f in files if f.endswith(".md")]
    return sorted(found, key=lambda p: p.relative_to(directory).as_posix())


def rule_matches(globs: list[str], paths: list[str]) -> bool:
    """Whether a rule covers the path: as in gitignore, the last glob that matches decides, and a `!` glob excludes."""
    matched = False
    for glob in globs:
        negated = glob.startswith("!")
        if glob_matches(glob[1:] if negated else glob, paths):
            matched = not negated
    return matched


def matching_rules(match_path: str) -> list[tuple[str, str]]:
    """(path under the rules directory, realpath) of each user rule whose globs match the path."""
    paths = candidates(match_path)
    directory = home() / ".claude/rules"
    found = []
    for rule in rule_files(directory):
        try:
            real = os.path.realpath(rule)
            if "\n" in real or not rule_matches(rule_globs(rule), paths):
                continue
        except OSError:
            continue
        found.append((rule.relative_to(directory).as_posix(), real))
    return found


def resolve(path: str | os.PathLike[str]) -> Path:
    return Path(os.path.realpath(path))


def file_realpath(given: object, cwd: object) -> str | None:
    """The realpath of a tool call's `file_path`, relative to `cwd`, or None when either is not a valid path."""
    if valid_path(given) and (cwd is None or valid_path(cwd)):
        return os.path.realpath(os.path.join(cwd or "", os.path.expanduser(given)))
    return None


def is_skipped(path: Path) -> bool:
    roots = [resolve(Path(os.environ.get("XDG_CACHE_HOME") or home() / ".cache") / "claude-tmp")]
    if os.environ.get("TMPDIR"):
        roots.append(resolve(os.environ["TMPDIR"]))
    if any(path.is_relative_to(root) for root in roots):
        return True
    parts = path.parts
    return any(parts[i:i + len(SCRATCH_PARTS)] == SCRATCH_PARTS for i in range(len(parts)))


def match_path_for(path: Path, folder: Path) -> str:
    for base in (folder, resolve(home())):
        if path.is_relative_to(base):
            return path.relative_to(base).as_posix()
    return path.as_posix()


def join_names(names: list[str]) -> str:
    if len(names) <= 2:
        return " and ".join(names)
    return ", ".join(names[:-1]) + ", and " + names[-1]


def forget_agent(data: dict) -> None:
    session, key = agent_ids(data)
    if session and key:
        with locked_records(state_dir() / session) as records:
            records.difference_update({r for r in records if r[0].split("/", 1)[0] == key})


def mark_loaded(records: set[tuple[str, ...]], key: str, rule: str) -> None:
    """Record the rule as in the agent's context, and drop the agent's denied edits for it."""
    records.difference_update({r for r in records if r[1] == rule and r[0].startswith(f"{key}/")})
    records.add((key, rule))


def on_instructions_loaded(data: dict) -> None:
    reason, rule = data.get("load_reason"), data.get("file_path")
    if reason == "compact":
        forget_agent(data)
        return
    session, key = agent_ids(data)
    if reason != "path_glob_match" or not session or not key or not valid_path(rule):
        return
    # A newline in the stored realpath would split the record.
    real = os.path.realpath(rule)
    if "\n" in real:
        return
    with locked_records(state_dir() / session) as records:
        mark_loaded(records, key, real)


def result_text(response: object) -> str:
    """The text of a tool result as the agent receives it: one string, or the text blocks of a list."""
    if isinstance(response, str):
        return response
    blocks = response if isinstance(response, list) else []
    texts = [block.get("text") for block in blocks if isinstance(block, dict) and block.get("type") == "text"]
    return "\n".join(text for text in texts if isinstance(text, str))


def read_calls(data: dict) -> list[tuple[str, str]]:
    """(realpath, result text) of each Read call in the hook input's tool batch."""
    cwd, calls = data.get("cwd"), data.get("tool_calls")
    found = []
    for call in calls if isinstance(calls, list) else []:
        if not isinstance(call, dict) or call.get("tool_name") != "Read":
            continue
        tool_input = call.get("tool_input")
        real = file_realpath(tool_input.get("file_path") if isinstance(tool_input, dict) else None, cwd)
        if real is not None:
            found.append((real, result_text(call.get("tool_response"))))
    return found


def shows_whole_rule(shown: str, rule: str) -> bool:
    """Whether the text holds every non-blank line of the rule file, in order, each at the end of a line.

    False for a rule that cannot be read or is not a regular file.
    """
    try:
        with open_rule(rule) as f:
            if f is None:
                return False
            wanted = [line for line in f.read().splitlines() if line.strip()]
    except OSError:
        return False
    # A Read result puts a number before each line, so a rule line is matched at the end of a shown line. Each search
    # goes on where the last one stopped, which keeps the rule's line order.
    remaining = iter(shown.splitlines())
    for want in wanted:
        if not any(line.endswith(want) for line in remaining):
            return False
    return True


def rules_read_whole(data: dict) -> set[str]:
    """The realpaths of the user rules whose whole text a Read call in the hook input's tool batch returned."""
    reads = read_calls(data)
    if not reads:
        return set()
    rules = {os.path.realpath(rule) for rule in rule_files(home() / ".claude/rules")}
    # A newline in the stored realpath would split the record.
    return {real for real, shown in reads if real in rules and "\n" not in real and shows_whole_rule(shown, real)}


def end_denied_batch(records: set[tuple[str, ...]], key: str) -> None:
    """Mark the edits denied in the agent's ended batch as shown to it, so its next edit of such a file is a retry."""
    ended = {(owner, rule) for owner, rule in records if owner.startswith(f"{key}/") and owner.endswith("/batch")}
    records.difference_update(ended)
    records.update((owner.removesuffix("/batch"), rule) for owner, rule in ended)


def on_post_tool_batch(data: dict) -> None:
    """Update the agent's records at the end of its tool batch: denied edits and rules it read whole.

    Claude Code sends this once per batch, after every call in it, before the agent's next model request. It skips a
    batch the user interrupts, so the agent's next edit of a file denied there is denied once more.
    """
    session, key = agent_ids(data)
    if not (session and key):
        return
    path = state_dir() / session
    read = rules_read_whole(data)
    # Sessions without denied edits or rule reads keep no state file; any other error must surface.
    if not read:
        try:
            path.stat()
        except FileNotFoundError:
            return
    with locked_records(path) as records:
        end_denied_batch(records, key)
        for rule in read:
            mark_loaded(records, key, rule)


def on_pre_tool_use(data: dict) -> str | None:
    tool_input, cwd = data.get("tool_input"), data.get("cwd")
    if data.get("tool_name") not in EDIT_TOOLS or not isinstance(tool_input, dict):
        return None
    given = tool_input.get("file_path")
    real = file_realpath(given, cwd)
    folder = os.environ.get("CLAUDE_PROJECT_DIR") or cwd
    session, key = agent_ids(data)
    if real is None or not (valid_path(folder) and session and key):
        return None
    prune(state_dir())
    path = Path(real)
    if is_skipped(path):
        return None
    rules = matching_rules(match_path_for(path, resolve(folder)))
    if not rules:
        return None
    # Every edit of a file is denied until the agent's tool batch ends, because the agent sent them all before it saw a
    # deny. Its next edit of that file is the retry, and the rule counts as read from then on.
    denied = f"{key}/{hashlib.sha256(os.fsencode(path)).hexdigest()}"
    unread = []
    with locked_records(state_dir() / session) as records:
        for name, real in rules:
            if (key, real) in records:
                continue
            if (denied, real) in records:
                mark_loaded(records, key, real)
            else:
                records.add((f"{denied}/batch", real))
                unread.append((name, real))
    if not unread:
        return None
    listed = join_names([f"~/.claude/rules/{name}" for name, _ in unread])
    return (f"rule-gate: the rules for {given} may not be in your context yet. Read {listed}, then retry this edit, "
            "changed if those rules require it. Skip a read only if that rule's full text is already in your context.")


def read_input() -> dict | None:
    """The hook's input object, or None when stdin is not a JSON object."""
    try:
        data = json.load(sys.stdin)
    except (ValueError, RecursionError):
        return None
    return data if isinstance(data, dict) else None


def main() -> int:
    try:
        data = read_input()
        if data is None:
            return 0
        event = data.get("hook_event_name")
        if event == "InstructionsLoaded":
            on_instructions_loaded(data)
            return 0
        if event == "PreCompact":
            forget_agent(data)
            return 0
        if event == "PostToolBatch":
            on_post_tool_batch(data)
            return 0
        reason = on_pre_tool_use(data) if event == "PreToolUse" else None
    except Exception as error:
        # Exit 1 so Claude Code shows a non-blocking warning and still runs the edit; exit 2 would block it.
        print(f"rule-gate failed: {error}", file=sys.stderr)
        return 1
    if reason:
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
