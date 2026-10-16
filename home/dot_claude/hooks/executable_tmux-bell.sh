#!/bin/sh
# Stop and Notification (permission_prompt) hook: rings the bell in this tmux
# pane, so tmux flags the window while Claude waits for input.
# Skips unattended runs (claude -p) and sessions outside tmux.
[ "${CLAUDE_CODE_SESSION_ATTENDED:-1}" = 0 ] && exit 0
[ -n "$TMUX_PANE" ] || exit 0
tty=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null) || exit 0
[ -w "$tty" ] && printf '\a' >"$tty"
exit 0
