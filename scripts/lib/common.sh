#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -t 2 ]]; then
  _DOTFILES_CLR_RESET=$'\033[0m'
  _DOTFILES_CLR_INFO=$'\033[1;34m'
  _DOTFILES_CLR_WARN=$'\033[1;33m'
  _DOTFILES_CLR_ERR=$'\033[1;31m'
else
  _DOTFILES_CLR_RESET=''
  _DOTFILES_CLR_INFO=''
  _DOTFILES_CLR_WARN=''
  _DOTFILES_CLR_ERR=''
fi

_DOTFILES_BACKUP_STAMP="${DOTFILES_BACKUP_STAMP:-$(date +%Y%m%d-%H%M%S)}"
export DOTFILES_BACKUP_STAMP="$_DOTFILES_BACKUP_STAMP"
_DOTFILES_BACKUP_ROOT="${DOTFILES_BACKUP_DIR:-$HOME/.dotfiles-backup/$_DOTFILES_BACKUP_STAMP}"

log() {
  printf '%s[INFO]%s %s\n' "$_DOTFILES_CLR_INFO" "$_DOTFILES_CLR_RESET" "$*"
}

warn() {
  printf '%s[WARN]%s %s\n' "$_DOTFILES_CLR_WARN" "$_DOTFILES_CLR_RESET" "$*" >&2
}

die() {
  printf '%s[ERROR]%s %s\n' "$_DOTFILES_CLR_ERR" "$_DOTFILES_CLR_RESET" "$*" >&2
  exit 1
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

is_dry_run() {
  [[ "${DRY_RUN:-0}" == "1" ]]
}

run_or_print() {
  if is_dry_run; then
    printf '[DRY-RUN]'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

run_or_print_shell() {
  local command="$1"

  if is_dry_run; then
    printf '[DRY-RUN] %s\n' "$command"
    return 0
  fi

  bash -Eeuo pipefail -c "$command"
}

ensure_dir() {
  local dir_path="$1"

  if [[ -d "$dir_path" ]]; then
    return 0
  fi

  if [[ -e "$dir_path" ]]; then
    die "Cannot create directory: '$dir_path' already exists and is not a directory"
  fi

  run_or_print mkdir -p "$dir_path"
}

ensure_path_line() {
  local rc_file="$1"
  local export_line="$2"

  ensure_dir "$(dirname "$rc_file")"

  if [[ ! -e "$rc_file" && ! -L "$rc_file" ]]; then
    run_or_print touch "$rc_file"
  fi

  if grep -Fqx "$export_line" "$rc_file" 2>/dev/null; then
    return 0
  fi

  if is_dry_run; then
    printf '[DRY-RUN] append to %q: %s\n' "$rc_file" "$export_line"
    return 0
  fi

  printf '\n%s\n' "$export_line" >>"$rc_file"
}

backup_path() {
  local source_path="$1"

  if [[ ! -e "$source_path" && ! -L "$source_path" ]]; then
    return 0
  fi

  ensure_dir "$_DOTFILES_BACKUP_ROOT"

  local relative_path
  if [[ "$source_path" == "$HOME/"* ]]; then
    relative_path="${source_path#$HOME/}"
  else
    relative_path="$(basename "$source_path")"
  fi

  local target_path="$_DOTFILES_BACKUP_ROOT/$relative_path"
  ensure_dir "$(dirname "$target_path")"

  local suffix=1
  while [[ -e "$target_path" || -L "$target_path" ]]; do
    target_path="$_DOTFILES_BACKUP_ROOT/${relative_path}.bak${suffix}"
    suffix=$((suffix + 1))
  done

  log "Backup: $source_path -> $target_path"
  run_or_print mv "$source_path" "$target_path"
}

is_ostree_host() {
  [[ -e /run/ostree-booted ]]
}

is_distrobox() {
  if [[ -f /run/.containerenv ]]; then
    return 0
  fi

  if [[ -n "${DISTROBOX_ENTER_PATH:-}" || -n "${CONTAINER_ID:-}" ]]; then
    return 0
  fi

  return 1
}

repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
  (cd "$script_dir" && git rev-parse --show-toplevel 2>/dev/null) \
    || (cd "$script_dir/../.." && pwd)
}

# download <url> <destination>
# Idempotent: if destination already exists with non-zero size, skip.
download() {
  local url="$1"
  local dest="$2"

  if [[ -s "$dest" ]]; then
    log "Already exists: $dest"
    return 0
  fi

  ensure_dir "$(dirname "$dest")"

  if has_cmd curl; then
    run_or_print curl -fsSL --retry 3 -o "$dest" "$url"
  elif has_cmd wget; then
    run_or_print wget -q -O "$dest" "$url"
  else
    die "Neither curl nor wget is available to download $url"
  fi
}

# Run fc-cache against a directory, idempotently and quietly.
fc_cache_dir() {
  local dir="$1"
  if ! has_cmd fc-cache; then
    warn "fc-cache is not available; skipping font cache refresh"
    return 0
  fi
  run_or_print fc-cache -f "$dir" >/dev/null 2>&1 || warn "fc-cache returned an error for $dir"
}

# ---------------------------------------------------------------
# Summary helpers: scripts can collect outcomes and print at end.
# ---------------------------------------------------------------
declare -a _DOTFILES_SUMMARY_OK=()
declare -a _DOTFILES_SUMMARY_SKIP=()
declare -a _DOTFILES_SUMMARY_FAIL=()
declare -a _DOTFILES_SUMMARY_NOTE=()

summary_ok()   { _DOTFILES_SUMMARY_OK+=("$*"); }
summary_skip() { _DOTFILES_SUMMARY_SKIP+=("$*"); }
summary_fail() { _DOTFILES_SUMMARY_FAIL+=("$*"); }
summary_note() { _DOTFILES_SUMMARY_NOTE+=("$*"); }

print_summary() {
  local title="${1:-Summary}"
  printf '\n%s==== %s ====%s\n' "$_DOTFILES_CLR_INFO" "$title" "$_DOTFILES_CLR_RESET"

  if (( ${#_DOTFILES_SUMMARY_OK[@]} > 0 )); then
    printf '  OK (%d):\n' "${#_DOTFILES_SUMMARY_OK[@]}"
    printf '    - %s\n' "${_DOTFILES_SUMMARY_OK[@]}"
  fi
  if (( ${#_DOTFILES_SUMMARY_SKIP[@]} > 0 )); then
    printf '  Skipped (%d):\n' "${#_DOTFILES_SUMMARY_SKIP[@]}"
    printf '    - %s\n' "${_DOTFILES_SUMMARY_SKIP[@]}"
  fi
  if (( ${#_DOTFILES_SUMMARY_FAIL[@]} > 0 )); then
    printf '  Failed (%d):\n' "${#_DOTFILES_SUMMARY_FAIL[@]}"
    printf '    - %s\n' "${_DOTFILES_SUMMARY_FAIL[@]}"
  fi
  if (( ${#_DOTFILES_SUMMARY_NOTE[@]} > 0 )); then
    printf '  Notes:\n'
    printf '    * %s\n' "${_DOTFILES_SUMMARY_NOTE[@]}"
  fi

  if (( ${#_DOTFILES_SUMMARY_FAIL[@]} > 0 )); then
    return 1
  fi
  return 0
}
