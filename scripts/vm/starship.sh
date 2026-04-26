#!/usr/bin/env bash
# scripts/vm/starship.sh
# Install the starship prompt into $HOME/.local/bin using the official
# installer from starship.rs. Fedora 44 doesn't ship starship in its main
# repos and we'd rather avoid pulling in a third-party COPR.
# Idempotent: skips if starship is already in PATH.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

STARSHIP_INSTALL_URL="${STARSHIP_INSTALL_URL:-https://starship.rs/install.sh}"
STARSHIP_BIN_DIR="${STARSHIP_BIN_DIR:-$HOME/.local/bin}"

ensure_local_bin_in_path() {
  ensure_dir "$STARSHIP_BIN_DIR"
  ensure_path_line "$HOME/.profile" 'export PATH="$HOME/.local/bin:$PATH"'
  if [[ ":${PATH:-}:" != *":$STARSHIP_BIN_DIR:"* ]]; then
    export PATH="$STARSHIP_BIN_DIR:$PATH"
  fi
}

install_starship() {
  if has_cmd starship; then
    log "starship already installed: $(starship --version 2>/dev/null | head -n1) ($(command -v starship))"
    summary_skip "starship already installed"
    return 0
  fi

  local installer
  installer="$(mktemp /tmp/starship-install.XXXXXX.sh)"
  download "$STARSHIP_INSTALL_URL" "$installer"

  log "Ejecutando instalador oficial de starship -> $STARSHIP_BIN_DIR"
  if is_dry_run; then
    printf '[DRY-RUN] sh %q --bin-dir %q --yes\n' "$installer" "$STARSHIP_BIN_DIR"
    rm -f "$installer"
    summary_ok "starship: dry-run"
    return 0
  fi

  local rc=0
  sh "$installer" --bin-dir "$STARSHIP_BIN_DIR" --yes >/dev/null 2>&1 || rc=$?
  rm -f "$installer"

  if (( rc != 0 )); then
    summary_fail "starship installer returned rc=$rc"
    summary_note "Reintenta manualmente: curl -sS $STARSHIP_INSTALL_URL | sh -s -- --bin-dir \"$STARSHIP_BIN_DIR\" --yes"
    return 1
  fi

  if has_cmd starship; then
    summary_ok "starship installed at $(command -v starship)"
  else
    summary_fail "starship does not appear in PATH after install (is $STARSHIP_BIN_DIR missing from PATH?)"
    summary_note "Reabre el shell o exporta: export PATH=\"$STARSHIP_BIN_DIR:\$PATH\""
    return 1
  fi
}

main() {
  log "=== starship.sh === (DRY_RUN=${DRY_RUN:-0})"
  ensure_local_bin_in_path

  local rc=0
  install_starship || rc=$?

  print_summary "Starship (vm)" || rc=1
  return $rc
}

main "$@"
