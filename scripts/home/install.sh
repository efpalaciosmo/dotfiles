#!/usr/bin/env bash
# scripts/home/install.sh
# Orchestrator for the `home` profile on Fedora Silverblue / Atomic.
# Idempotent. Honors DRY_RUN=1.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

REQUIRED_BIN=(bash tar python3 podman flatpak)
OPTIONAL_DOWNLOAD=(curl wget)

validate_environment() {
  if is_distrobox; then
    die "You are inside Distrobox. 'make home' is for the host. Exit with 'exit' and run it on the host."
  fi

  if is_ostree_host; then
    log "Detected host: ostree/atomic (Fedora Silverblue / Atomic)."
  else
    warn "Host does NOT look ostree/atomic. Continuing, but some assumptions (rpm-ostree, no dnf) may not apply."
  fi

  local cmd missing=()
  for cmd in "${REQUIRED_BIN[@]}"; do
    if ! has_cmd "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    die "Missing commands on host: ${missing[*]}"
  fi

  local ok_dl=0
  for cmd in "${OPTIONAL_DOWNLOAD[@]}"; do
    if has_cmd "$cmd"; then
      ok_dl=1
      break
    fi
  done
  (( ok_dl == 1 )) || die "Need 'curl' or 'wget' to download fonts/installers"

  log "Environment validation OK"
}

ensure_local_bin_path() {
  ensure_dir "$HOME/.local/bin"

  local line='export PATH="$HOME/.local/bin:$PATH"'
  ensure_path_line "$HOME/.profile" "$line"

  if [[ -f "$HOME/.bashrc" || -L "$HOME/.bashrc" ]]; then
    ensure_path_line "$HOME/.bashrc" "$line"
  fi

  if [[ -f "$HOME/.zshrc" || -L "$HOME/.zshrc" ]]; then
    ensure_path_line "$HOME/.zshrc" "$line"
  fi

  if [[ ":${PATH:-}:" != *":$HOME/.local/bin:"* ]]; then
    summary_note "This session: export PATH=\"\$HOME/.local/bin:\$PATH\" or restart the shell"
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

run_step() {
  local label="$1"; shift
  local script="$1"; shift

  printf '\n%s>> %s%s\n' "$_DOTFILES_CLR_INFO" "$label" "$_DOTFILES_CLR_RESET"

  if [[ ! -f "$script" ]]; then
    summary_fail "$label: script $script does not exist"
    return 0
  fi

  if bash "$script" "$@"; then
    summary_ok "Step: $label"
  else
    summary_fail "Step: $label (see output above)"
  fi
  return 0
}

main() {
  log "=== make home === (DRY_RUN=${DRY_RUN:-0})"
  log "REPO_ROOT=$REPO_ROOT"

  validate_environment
  ensure_local_bin_path

  run_step "Fonts (host)"           "$SCRIPT_DIR/fonts.sh"
  run_step "Distrobox + container" "$SCRIPT_DIR/distrobox.sh"
  run_step "Flatpaks (--user)"      "$SCRIPT_DIR/flatpaks.sh"
  run_step "Python user tools"      "$SCRIPT_DIR/python-user-tools.sh"
  run_step "Apply dotfiles (stown)" "$SCRIPT_DIR/../stown/apply.sh" home

  print_summary "make home" || true

  log "Done. Check backups in \$HOME/.dotfiles-backup/$DOTFILES_BACKUP_STAMP"
}

main "$@"
