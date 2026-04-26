#!/usr/bin/env bash
# scripts/vm/install.sh
# Orchestrator for the `vm` profile inside the `fedora` Distrobox container.
# Idempotent. Honors DRY_RUN=1.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

REQUIRED_BIN=(bash tar python3 dnf)
OPTIONAL_DOWNLOAD=(curl wget)

validate_environment() {
  if ! is_distrobox; then
    die "This target must run inside distrobox: distrobox enter fedora"
  fi

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" != "fedora" ]]; then
      die "The container is not Fedora (ID=${ID:-unknown}). Expected ID=fedora."
    fi
    log "Detected distro: ${PRETTY_NAME:-Fedora ${VERSION_ID:-?}}"
  else
    die "Cannot read /etc/os-release"
  fi

  local cmd missing=()
  for cmd in "${REQUIRED_BIN[@]}"; do
    has_cmd "$cmd" || missing+=("$cmd")
  done
  (( ${#missing[@]} == 0 )) || die "Missing commands in container: ${missing[*]}"

  local ok=0
  for cmd in "${OPTIONAL_DOWNLOAD[@]}"; do
    has_cmd "$cmd" && { ok=1; break; }
  done
  (( ok == 1 )) || die "Need 'curl' or 'wget' to download files"
}

ensure_local_bin_path() {
  ensure_dir "$HOME/.local/bin"

  # Only seed ~/.profile with a literal `export PATH=...` line when no
  # existing reference to `.local/bin` is found. The dotfile-managed
  # ~/.profile uses `_prepend_path "$HOME/.local/bin"` which is functionally
  # equivalent but does not match `ensure_path_line`'s exact-string check;
  # without this guard, every re-run would append a redundant duplicate to
  # the symlinked dotfile (polluting the repo).
  if ! grep -q '\.local/bin' "$HOME/.profile" 2>/dev/null; then
    ensure_path_line "$HOME/.profile" 'export PATH="$HOME/.local/bin:$PATH"'
  fi

  if [[ ":${PATH:-}:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

run_step() {
  local label="$1"; shift
  local script="$1"; shift

  printf '\n%s>> %s%s\n' "$_DOTFILES_CLR_INFO" "$label" "$_DOTFILES_CLR_RESET"

  if [[ ! -f "$script" ]]; then
    summary_fail "$label: $script does not exist"
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
  log "=== make vm === (DRY_RUN=${DRY_RUN:-0})"
  log "REPO_ROOT=$REPO_ROOT"

  validate_environment
  ensure_local_bin_path

  run_step "Fedora packages (dnf)"   "$SCRIPT_DIR/packages-fedora.sh"
  # starship is not in Fedora's main repos; install it with the official
  # installer into $HOME/.local/bin (without touching the system).
  run_step "Starship (prompt)"       "$SCRIPT_DIR/starship.sh"
  # python-user-tools installs 'stown' (via pip --user). It must run BEFORE
  # stown/apply.sh. The script lives in scripts/home/ but is profile-agnostic.
  run_step "Python user tools"       "$SCRIPT_DIR/../home/python-user-tools.sh"
  run_step "Fonts (vm)"              "$SCRIPT_DIR/fonts.sh"
  run_step "VS Code Insiders"        "$SCRIPT_DIR/vscode-insiders.sh"
  # Languages and runtimes (Go via gvm, fnm, Julia, Java via SDKMAN, uv,
  # Gradle, pnpm) are user-local. Zig intentionally comes from Fedora
  # packages above.
  run_step "Languages (vm)"          "$SCRIPT_DIR/languages.sh"
  # oh-my-zsh + plugins (autosuggestions, syntax-highlighting).
  run_step "Shell plugins (vm)"      "$SCRIPT_DIR/shell-plugins.sh"
  run_step "Apply dotfiles (stown)"  "$SCRIPT_DIR/../stown/apply.sh" vm
  # podman-compose is a Python tool installed with pip --user; run it AFTER
  # stown so dotfile-managed configuration is already in place.
  run_step "podman-compose"          "$SCRIPT_DIR/podman-compose.sh"

  print_summary "make vm" || true

  log "Done. Backups are in \$HOME/.dotfiles-backup/$DOTFILES_BACKUP_STAMP"
  log "Reminder: GOPATH=\$HOME/.go (not \$HOME/go). Reopen the shell for changes to take effect."
}

main "$@"
