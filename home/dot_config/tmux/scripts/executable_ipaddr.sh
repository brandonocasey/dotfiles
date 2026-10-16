#!/bin/sh
# tmux status: IPv4 address of the interface that holds the default route, on
# macOS and Linux.
case $(uname) in
Darwin)
  iface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
  [ -n "$iface" ] && ip=$(ifconfig "$iface" 2>/dev/null | awk '/inet / {print $2; exit}')
  ;;
*)
  ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "src") {print $(i + 1); exit}}')
  ;;
esac
printf '%s' "${ip:-offline}"
