#!/usr/bin/env bash
# scripts/vm/packages-fedora.sh
# Install development packages inside the Fedora 44 Distrobox container
# using dnf. Idempotent: dnf install -y is a no-op if already installed.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

# ---- Package groups (Fedora package names) ---------------------------

PKG_SHELL=(
  zsh
  bash-completion
  # starship is not in Fedora's main repos; scripts/vm/starship.sh installs it
  # with the official installer into $HOME/.local/bin.
)

PKG_TERMINAL=(
  tree
  fastfetch
  jq
  fd-find
  ripgrep
  fzf
  bat
  btop
  tmux
)

PKG_DEVTOOLS=(
  git
  gh
  neovim
  unzip
  tar
  xz
  wget
  curl
  ca-certificates
)

PKG_BUILD=(
  gcc
  gcc-c++
  clang
  clang-tools-extra
  llvm
  lldb
  cmake
  make
  ninja-build
  pkgconf-pkg-config
  gawk
  findutils
  # gvm builds Go from source by default; bison is required.
  bison
)

PKG_LANGUAGES=(
  python3
  python3-pip
  # Zig comes from Fedora, by preference; other toolchains are user-local.
  zig
)

ALL_PACKAGES=(
  "${PKG_SHELL[@]}"
  "${PKG_TERMINAL[@]}"
  "${PKG_DEVTOOLS[@]}"
  "${PKG_BUILD[@]}"
  "${PKG_LANGUAGES[@]}"
)

ensure_dnf() {
  if ! has_cmd dnf; then
    die "dnf is not available. Are you inside the expected Fedora image?"
  fi
}

makecache() {
  log ">>> dnf makecache --refresh"
  if run_or_print sudo dnf makecache --refresh; then
    log "<<< dnf makecache OK"
  else
    local rc=$?
    warn "<<< dnf makecache returned rc=$rc (continuing; cached repos may be enough)"
    summary_note "dnf makecache rc=$rc (probable network/repository issue)"
  fi
}

install_packages() {
  log ">>> dnf install -y (${#ALL_PACKAGES[@]} packages)"
  log "    Packages: ${ALL_PACKAGES[*]}"

  local install_rc=0
  if is_dry_run; then
    printf '[DRY-RUN] sudo dnf install -y'
    printf ' %q' "${ALL_PACKAGES[@]}"
    printf '\n'
  else
    sudo dnf install -y "${ALL_PACKAGES[@]}" || install_rc=$?
  fi
  log "<<< dnf install rc=$install_rc"

  if (( install_rc != 0 )); then
    summary_fail "dnf install -y returned rc=$install_rc"
    summary_note "If the transaction says 'Complete!' above, it may be a tolerable scriptlet failure (avahi/systemd); verify with 'rpm -q'."
  fi

  if is_dry_run; then
    summary_ok "dry-run: printed dnf command"
    return 0
  fi

  verify_installed
}

# Run `rpm -q` for each package and classify installed/missing packages.
# Some names are virtual (e.g. 'wget' is provided by 'wget2-wget' in
# Fedora 44), so also query --whatprovides as a fallback.
pkg_satisfied() {
  local pkg="$1"
  rpm -q "$pkg" >/dev/null 2>&1 && return 0
  rpm -q --whatprovides "$pkg" >/dev/null 2>&1
}

verify_installed() {
  local pkg installed=0 missing=0
  local -a missing_list=()

  while IFS= read -r pkg; do
    if pkg_satisfied "$pkg"; then
      installed=$((installed + 1))
    else
      missing=$((missing + 1))
      missing_list+=("$pkg")
    fi
  done < <(printf '%s\n' "${ALL_PACKAGES[@]}")

  log "rpm -q: $installed installed, $missing missing (of ${#ALL_PACKAGES[@]})"

  if (( missing == 0 )); then
    summary_ok "All packages present ($installed/${#ALL_PACKAGES[@]})"
    return 0
  fi

  warn "Packages that are NOT installed after 'dnf install':"
  printf '  - %s\n' "${missing_list[@]}" >&2
  summary_fail "Missing ${missing} packages: ${missing_list[*]}"
  summary_note "Reproduce manually: sudo dnf install -y ${missing_list[*]}"
  return 1
}

main() {
  log "=== packages-fedora.sh === (DRY_RUN=${DRY_RUN:-0})"
  ensure_dnf
  makecache

  # Keep package failures from aborting before the summary is printed: capture
  # the rc and propagate it at the end.
  local rc=0
  install_packages || rc=$?

  print_summary "Packages (vm, dnf)" || rc=1
  return $rc
}

main "$@"
