#!/usr/bin/env bash
# scripts/vm/vscode-insiders.sh
# Install VS Code Insiders inside the Fedora Distrobox container and set
# it as the default editor for text/plain (without breaking CLI workflows).
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

VSCODE_REPO_FILE="/etc/yum.repos.d/vscode.repo"
MS_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"

ensure_dnf() {
  has_cmd dnf || die "dnf is not available (are you in Fedora?)"
}

import_ms_key() {
  log "Importando llave Microsoft (rpm --import)"
  run_or_print sudo rpm --import "$MS_KEY_URL"
}

write_repo_file() {
  if [[ -f "$VSCODE_REPO_FILE" ]] && grep -Fq "[code]" "$VSCODE_REPO_FILE"; then
    log "Repo de VS Code ya configurado en $VSCODE_REPO_FILE"
    summary_skip "vscode.repo already exists"
    return 0
  fi

  if is_dry_run; then
    printf '[DRY-RUN] sudo tee %q\n' "$VSCODE_REPO_FILE"
    return 0
  fi

  log "Escribiendo $VSCODE_REPO_FILE"
  sudo tee "$VSCODE_REPO_FILE" >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
  summary_ok "vscode.repo creado"
}

install_code_insiders() {
  log "sudo dnf check-update (may return 100; ignoring that)"
  run_or_print bash -c 'sudo dnf check-update || true'

  if has_cmd code-insiders; then
    log "code-insiders already installed: $(code-insiders --version 2>/dev/null | head -n1)"
    summary_skip "code-insiders already installed"
    return 0
  fi

  log "Instalando code-insiders"
  if run_or_print sudo dnf install -y code-insiders; then
    summary_ok "code-insiders installed"
  else
    summary_fail "Could not install code-insiders"
    return 1
  fi
}

set_default_editor() {
  if ! has_cmd xdg-mime; then
    warn "xdg-mime is not available; skipping MIME association"
    summary_note "To associate manually: install xdg-utils and run xdg-mime default code-insiders.desktop text/plain"
    return 0
  fi

  local desktop=""
  if [[ -f /usr/share/applications/code-insiders.desktop ]]; then
    desktop="code-insiders.desktop"
  elif [[ -f /usr/share/applications/code.desktop ]]; then
    desktop="code.desktop"
  fi

  if [[ -z "$desktop" ]]; then
    warn "Could not find a VS Code desktop file (neither Insiders nor stable)."
    summary_note "Reintenta tras un re-login, o asocia manualmente con xdg-mime."
    return 0
  fi

  # xdg-mime writes ~/.config/mimeapps.list; the directory may not exist
  # in a freshly initialized container.
  ensure_dir "$HOME/.config"

  log "Asociando text/plain -> $desktop"
  if is_dry_run; then
    printf '[DRY-RUN] xdg-mime default %q text/plain\n' "$desktop"
    summary_ok "text/plain -> $desktop (dry-run)"
    return 0
  fi

  local xdg_err rc
  xdg_err="$(mktemp)"
  rc=0
  xdg-mime default "$desktop" text/plain 2>"$xdg_err" || rc=$?

  if (( rc == 0 )); then
    rm -f "$xdg_err"
    summary_ok "text/plain -> $desktop"
    return 0
  fi

  warn "xdg-mime failed (rc=$rc):"
  sed -e 's/^/  /' "$xdg_err" >&2 || true
  rm -f "$xdg_err"
  summary_fail "xdg-mime default $desktop text/plain (rc=$rc)"
  summary_note "Repara manualmente: mkdir -p \"\$HOME/.config\" && xdg-mime default $desktop text/plain"
  return 1
}

main() {
  if ! is_distrobox; then
    warn "Not inside Distrobox. Continuing, but VS Code Insiders should not be installed on the Silverblue host."
  fi

  ensure_dnf
  import_ms_key
  write_repo_file
  install_code_insiders
  set_default_editor

  print_summary "VS Code Insiders (vm)" || true
}

main "$@"
