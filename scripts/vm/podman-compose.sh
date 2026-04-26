#!/usr/bin/env bash
# scripts/vm/podman-compose.sh
# Install podman-compose with pip --user after python-user-tools has prepared pip.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

ALLOW_BREAK="${ALLOW_PIP_BREAK_SYSTEM_PACKAGES:-0}"

if [[ "$ALLOW_BREAK" == "0" ]] && is_distrobox; then
  ALLOW_BREAK=1
fi

ensure_local_bin() {
  ensure_dir "$HOME/.local/bin"
  ensure_path_line "$HOME/.profile" 'export PATH="$HOME/.local/bin:$PATH"'

  if [[ ":${PATH:-}:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

install_podman_compose() {
  if ! has_cmd python3; then
    summary_fail "python3 missing: install packages first with 'make packages-vm'"
    return 0
  fi
  if ! python3 -m pip --version >/dev/null 2>&1; then
    summary_fail "pip missing: run 'make python-user-tools' before podman-compose"
    return 0
  fi

  local pip_args=(install --user --upgrade podman-compose)
  if run_or_print python3 -m pip "${pip_args[@]}"; then
    summary_ok "podman-compose installed with pip --user"
  elif [[ "$ALLOW_BREAK" == "1" ]]; then
    warn "pip rejected the install; retrying with --break-system-packages (--user only)."
    if run_or_print python3 -m pip "${pip_args[@]}" --break-system-packages; then
      summary_ok "podman-compose installed with pip --user --break-system-packages"
    else
      summary_fail "podman-compose could not be installed"
    fi
  else
    summary_fail "podman-compose could not be installed"
  fi
}

main() {
  if ! is_distrobox; then
    warn "Distrobox was not detected. This script assumes it is running inside the container."
  fi

  ensure_local_bin
  install_podman_compose

  print_summary "podman-compose (vm)" || true
}

main "$@"
