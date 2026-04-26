#!/usr/bin/env bash
# scripts/check.sh
# Static validation of all shell scripts in the repo.
# Uses shellcheck if present; always runs `bash -n`.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

list_scripts() {
  find "$REPO_ROOT/scripts" -type f -name '*.sh' \
    -not -path '*/legacy/*' \
    | sort
}

bash_syntax_check() {
  log "bash -n over scripts/**/*.sh"
  local failed=0 script
  while IFS= read -r script; do
    if ! bash -n "$script"; then
      summary_fail "bash -n: $script"
      failed=1
    else
      summary_ok "bash -n: ${script#$REPO_ROOT/}"
    fi
  done < <(list_scripts)
  return $failed
}

shellcheck_run() {
  if ! has_cmd shellcheck; then
    summary_note "shellcheck is not installed: skipping deeper static analysis"
    return 0
  fi

  log "shellcheck over scripts/**/*.sh"
  local failed=0 script
  while IFS= read -r script; do
    if ! shellcheck \
        --severity=warning \
        --shell=bash \
        --external-sources \
        --source-path="$REPO_ROOT/scripts" \
        --source-path="$REPO_ROOT/scripts/lib" \
        "$script"; then
      summary_fail "shellcheck: ${script#$REPO_ROOT/}"
      failed=1
    fi
  done < <(list_scripts)

  if (( failed == 0 )); then
    summary_ok "shellcheck passed for all scripts"
  fi
  return $failed
}

main() {
  log "=== make check ==="

  local rc=0
  bash_syntax_check || rc=1
  shellcheck_run    || rc=1

  print_summary "check" || rc=1
  exit $rc
}

main "$@"
