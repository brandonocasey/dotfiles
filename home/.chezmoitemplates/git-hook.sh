#!/bin/sh
# Global git hook (core.hooksPath). On pre-commit it scans staged changes for
# secrets. It then runs the repo's own hook of the same name, which a global
# hooksPath would otherwise hide.
name=$(basename "$0")

if [ "$name" = pre-commit ]; then
  if command -v gitleaks >/dev/null 2>&1; then
    gitleaks git --staged --redact --no-banner --log-level warn -v || {
      echo "pre-commit: gitleaks found secrets in the staged changes; commit blocked." >&2
      exit 1
    }
  else
    echo "pre-commit: gitleaks is not installed; secret scan skipped." >&2
  fi
fi

common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
repo_hook="$common/hooks/$name"
if [ -x "$repo_hook" ] && ! [ "$repo_hook" -ef "$0" ]; then
  exec "$repo_hook" "$@"
fi
exit 0
