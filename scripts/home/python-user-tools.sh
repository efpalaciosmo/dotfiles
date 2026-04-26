#!/usr/bin/env bash
# scripts/home/python-user-tools.sh
# Bootstrap pip in user-space and install/upgrade `stown`.
# Designed for Fedora Silverblue / Atomic where the host should not be
# polluted with system-wide python packages.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

GET_PIP_URL="${GET_PIP_URL:-https://bootstrap.pypa.io/get-pip.py}"
ALLOW_BREAK="${ALLOW_PIP_BREAK_SYSTEM_PACKAGES:-0}"

# Distrobox is a sandbox; PEP 668 / EXTERNALLY-MANAGED does not protect us
# from anything useful there, and the --break-system-packages fallback only
# writes to $HOME/.local. Enable the option by default if it was not passed.
if [[ "$ALLOW_BREAK" == "0" ]] && is_distrobox; then
  ALLOW_BREAK=1
  log "Detected distrobox: enabling --break-system-packages for pip --user (sandbox)."
fi

ensure_python() {
  if ! has_cmd python3; then
    die "python3 is not available. It should be included on Silverblue."
  fi
}

ensure_pip() {
  if python3 -m pip --version >/dev/null 2>&1; then
    log "pip already available: $(python3 -m pip --version)"
    return 0
  fi

  log "pip is not available. Bootstrapping with get-pip.py."
  local tmp
  tmp="$(mktemp /tmp/get-pip.XXXXXX.py)"
  download "$GET_PIP_URL" "$tmp"

  if is_dry_run; then
    printf '[DRY-RUN] python3 %q --user\n' "$tmp"
    rm -f "$tmp"
    return 0
  fi

  if ! python3 "$tmp" --user; then
    rm -f "$tmp"
    die "Could not bootstrap pip --user"
  fi
  rm -f "$tmp"
}

ensure_local_bin_in_path() {
  ensure_dir "$HOME/.local/bin"
  ensure_path_line "$HOME/.profile" 'export PATH="$HOME/.local/bin:$PATH"'

  if [[ ":${PATH:-}:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

pip_user_install() {
  local pkg="$1"
  if run_or_print python3 -m pip install --user --upgrade "$pkg"; then
    return 0
  fi

  warn "pip install --user failed (possible PEP 668 / externally-managed)."

  if [[ "$ALLOW_BREAK" == "1" ]]; then
    warn "ALLOW_PIP_BREAK_SYSTEM_PACKAGES=1 is active: retrying with --break-system-packages (--user only)."
    run_or_print python3 -m pip install --user --upgrade --break-system-packages "$pkg"
    return $?
  fi

  cat <<EOF >&2
[python-user-tools] The Python interpreter rejected the install. This usually
happens on distros with PEP 668. Since the host is Silverblue, you can usually:

  1) Retry with the explicit variable:
       ALLOW_PIP_BREAK_SYSTEM_PACKAGES=1 make home

  2) Or install 'stown' inside the distrobox container and put it in the host
     PATH (advanced), or use pipx.

EOF
  return 1
}

ensure_stown() {
  if has_cmd stown; then
    log "stown already available: $(stown --version 2>/dev/null || echo unknown)"
    summary_skip "stown already installed"
    return 0
  fi

  log "Installing 'stown' with --user"
  if pip_user_install stown; then
    summary_ok "stown installed with --user"
  else
    summary_fail "stown could not be installed"
    return 1
  fi
}

main() {
  ensure_python
  ensure_pip
  ensure_local_bin_in_path
  ensure_stown

  print_summary "python-user-tools (stown, pip)" || true
}

main "$@"
