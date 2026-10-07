#!/usr/bin/env bash
set -euo pipefail

readonly SELF="${BASH_SOURCE[0]:-}"
readonly -a CORE=(git jq rg python3 gh chezmoi node)
readonly -a SEARCH_DIRS=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOME/.linuxbrew/bin"
  /home/linuxbrew/.linuxbrew/bin
  /opt/homebrew/bin
  /usr/local/bin
  /usr/bin
  /bin
)

usage() {
  printf 'Usage: %s [--check] [--remote USER@HOST] [--list] [TOOL|COMMAND=FORMULA ...]\n' \
    "${0##*/}"
}

formula_for() {
  case "$1" in
    git) printf '%s\n' git ;;
    jq) printf '%s\n' jq ;;
    rg) printf '%s\n' ripgrep ;;
    python3) printf '%s\n' python ;;
    gh) printf '%s\n' gh ;;
    chezmoi) printf '%s\n' chezmoi ;;
    node) printf '%s\n' node ;;
    shellcheck) printf '%s\n' shellcheck ;;
    shfmt) printf '%s\n' shfmt ;;
    fd) printf '%s\n' fd ;;
    yq) printf '%s\n' yq ;;
    glab) printf '%s\n' glab ;;
    uv) printf '%s\n' uv ;;
    *) return 1 ;;
  esac
}

list_tools() {
  local tool
  for tool in git jq rg python3 gh chezmoi node shellcheck shfmt fd yq glab uv; do
    printf '%-12s %s\n' "$tool" "$(formula_for "$tool")"
  done
}

find_command() {
  local command_name=$1 path candidate
  if path=$(command -v "$command_name" 2>/dev/null); then
    printf '%s\n' "$path"
    return 0
  fi
  for candidate in "${SEARCH_DIRS[@]}"; do
    if [[ -x "$candidate/$command_name" ]]; then
      printf '%s\n' "$candidate/$command_name"
      return 0
    fi
  done
  return 1
}

brew_command() {
  local path
  if [[ $(id -u) -eq 0 && -x /root/bin/brew ]]; then
    printf '%s\n' /root/bin/brew
    return 0
  fi
  if path=$(find_command brew); then
    printf '%s\n' "$path"
    return 0
  fi
  return 1
}

run_remote() {
  local remote=$1
  shift
  local quoted=() arg
  for arg in "$@"; do
    printf -v arg '%q' "$arg"
    quoted+=("$arg")
  done
  ssh -a -T -o RemoteCommand=none -o BatchMode=yes -o ConnectTimeout=10 "$remote" \
    "bash -s -- ${quoted[*]}" < "$SELF"
}

valid_remote() {
  [[ $1 != -* && $1 =~ ^([A-Za-z0-9._-]+@)?[A-Za-z0-9][A-Za-z0-9._-]*$ ]]
}

brew_account_home() {
  local account=$1 entry
  entry=$(getent passwd "$account") || return 1
  printf '%s\n' "${entry#*:*:*:*:*:}" | cut -d: -f1
}

make_brew_scratch() {
  local account=$1 account_home=$2 base scratch group
  base="${XDG_CACHE_HOME:-$account_home/.cache}/agents/scratch/llm-tools"
  if [[ $(id -u) -eq 0 && $account != root ]]; then
    base="$account_home/.cache/agents/scratch/llm-tools"
    group=$(id -gn "$account")
    install -d -m 700 -o "$account" -g "$group" "$base"
    scratch=$(mktemp -d "$base/run.XXXXXXXX")
    chown "$account:$group" "$scratch"
  else
    mkdir -p "$base"
    chmod 700 "$base"
    scratch=$(mktemp -d "$base/run.XXXXXXXX")
  fi
  printf '%s\n' "$scratch"
}

mode=install
remote=
remote_set=false
list=false
tools=()
while (($#)); do
  case "$1" in
    --check) mode=check ;;
    --remote)
      [[ $# -ge 2 ]] || { printf '%s\n' 'error: --remote needs USER@HOST' >&2; exit 2; }
      remote=$2
      remote_set=true
      shift
      ;;
    --list) list=true ;;
    -h|--help) usage; exit 0 ;;
    --*) printf 'error: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) tools+=("$1") ;;
  esac
  shift
done

if [[ $remote_set == true ]] && ! valid_remote "$remote"; then
  printf 'error: invalid remote host: %s\n' "$remote" >&2
  exit 2
fi

if [[ $list == true ]]; then
  list_tools
  exit 0
fi

if [[ $remote_set == true ]]; then
  remote_args=()
  [[ $mode == check ]] && remote_args+=(--check)
  remote_args+=("${tools[@]}")
  run_remote "$remote" "${remote_args[@]}"
  exit $?
fi

((${#tools[@]})) || tools=("${CORE[@]}")
missing_tools=()
missing_formulas=()
for specification in "${tools[@]}"; do
  if [[ $specification == *=* ]]; then
    tool=${specification%%=*}
    formula=${specification#*=}
    if [[ ! $tool =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]]; then
      printf 'error: invalid command name: %s\n' "$tool" >&2
      exit 2
    fi
    if [[ ! $formula =~ ^[A-Za-z0-9][A-Za-z0-9@+._-]*(/[A-Za-z0-9][A-Za-z0-9@+._-]*){0,2}$ ]]; then
      printf 'error: invalid formula name: %s\n' "$formula" >&2
      exit 2
    fi
  else
    tool=$specification
    if ! formula=$(formula_for "$tool"); then
      printf 'error: unsupported tool: %s (use --list or COMMAND=FORMULA)\n' "$tool" >&2
      exit 2
    fi
  fi
  if path=$(find_command "$tool"); then
    printf 'available %-12s %s\n' "$tool" "$path"
  else
    printf 'missing   %-12s formula=%s\n' "$tool" "$formula"
    missing_tools+=("$tool")
    missing_formulas+=("$formula")
  fi
done

((${#missing_tools[@]})) || exit 0
[[ $mode == install ]] || exit 1

if ! brew=$(brew_command); then
  printf '%s\n' 'error: Homebrew is required but was not found; install it separately' >&2
  exit 3
fi

brew_account=$(id -un)
brew_home=$HOME
if [[ $brew == /root/bin/brew ]]; then
  brew_account=linuxbrew
  if ! brew_home=$(brew_account_home "$brew_account"); then
    printf 'error: cannot find the Homebrew account: %s\n' "$brew_account" >&2
    exit 3
  fi
fi
brew_scratch=$(make_brew_scratch "$brew_account" "$brew_home")
trap 'find "$brew_scratch" -depth -delete; rmdir "${brew_scratch%/*}" 2>/dev/null || true' EXIT
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_UPGRADE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_TEMP="$brew_scratch"
export TMPDIR="$brew_scratch"

for formula in "${missing_formulas[@]}"; do
  "$brew" info "$formula" >/dev/null
done
"$brew" install "${missing_formulas[@]}"

status=0
for tool in "${missing_tools[@]}"; do
  if path=$(find_command "$tool"); then
    printf 'installed %-12s %s\n' "$tool" "$path"
  else
    printf 'error: formula installed but command is unavailable: %s\n' "$tool" >&2
    status=4
  fi
done
exit "$status"
