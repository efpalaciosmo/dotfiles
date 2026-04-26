#!/usr/bin/env bash
# scripts/home/flatpaks.sh
# Configure Flathub as a USER remote (not system) and install a curated
# list of apps with --user. Idempotent and resilient: invalid IDs do not
# abort the run, they are reported in the final summary.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

FLATHUB_REPO_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"

FLATPAK_APPS=(
  app.zen_browser.zen
  com.github.xournalpp.xournalpp
  org.gnome.Papers
  com.usebottles.bottles
  com.github.tchx84.Flatseal
  org.gnome.Firmware
  net.opentabletdriver.OpenTabletDriver
  io.missioncenter.MissionCenter
  com.github.marhkb.Pods
  re.sonny.Workbench
  re.sonny.Playhouse
  org.mozilla.Thunderbird
  org.telegram.desktop
  com.discordapp.Discord
  com.brave.Browser
  org.qbittorrent.qBittorrent
  org.kde.kdenlive
  com.github.flxzt.rnote
  org.gimp.GIMP
  com.valvesoftware.Steam
  com.valvesoftware.Steam.CompatibilityTool.Proton-GE
  com.obsproject.Studio
  com.obsproject.Studio.Plugin.OBSPWVideo
  com.obsproject.Studio.Plugin.GStreamerVaapi
  org.virt_manager.virt-manager
  org.virt_manager.virt_manager.Extension.Qemu
)

ensure_flatpak() {
  if ! has_cmd flatpak; then
    die "flatpak is not installed on the host. It should be included on Fedora Silverblue."
  fi
}

remove_system_flathub_if_present() {
  if ! flatpak remotes --system 2>/dev/null | awk '{print $1}' | grep -Fxq flathub; then
    return 0
  fi

  log "Detected system-level 'flathub' remote. Trying to remove it (may ask for sudo)."

  if is_dry_run; then
    printf '[DRY-RUN] sudo flatpak remote-delete --system flathub\n'
    summary_skip "Remove system 'flathub' remote (dry-run)"
    return 0
  fi

  if sudo -n true 2>/dev/null; then
    if sudo flatpak remote-delete --system flathub; then
      summary_ok "Removed system 'flathub' remote"
    else
      summary_fail "sudo flatpak remote-delete --system flathub failed"
      summary_note "Ejecuta manualmente: sudo flatpak remote-delete --system flathub"
    fi
  else
    summary_fail "No non-interactive sudo available to remove the system remote"
    summary_note "Ejecuta manualmente: sudo flatpak remote-delete --system flathub"
  fi
}

ensure_user_flathub() {
  if flatpak remotes --user 2>/dev/null | awk '{print $1}' | grep -Fxq flathub; then
    log "Remoto 'flathub' ya configurado a nivel USER"
    summary_skip "Remoto user flathub"
    return 0
  fi

  log "Adding USER remote 'flathub' -> $FLATHUB_REPO_URL"
  if run_or_print flatpak --user remote-add --if-not-exists flathub "$FLATHUB_REPO_URL"; then
    summary_ok "User flathub remote added"
  else
    summary_fail "Could not add user flathub remote"
    die "Cannot continue without a Flathub remote"
  fi
}

# Resolve the catalog of available app IDs once (cached in a file).
load_remote_app_catalog() {
  if is_dry_run; then
    printf '[DRY-RUN] flatpak remote-ls --user flathub --app --columns=application\n'
    REMOTE_CATALOG=""
    return 0
  fi

  log "Querying Flathub catalog (may take a few seconds)..."
  if ! REMOTE_CATALOG="$(flatpak remote-ls --user flathub --app --columns=application 2>/dev/null)"; then
    warn "Could not list the Flathub catalog (no network?). Continuing without ID validation."
    REMOTE_CATALOG=""
  fi
}

is_app_in_catalog() {
  local app="$1"
  [[ -z "$REMOTE_CATALOG" ]] && return 0  # Cannot validate -> assume OK
  grep -Fxq "$app" <<<"$REMOTE_CATALOG"
}

is_app_installed_user() {
  local app="$1"
  flatpak list --user --app --columns=application 2>/dev/null | grep -Fxq "$app"
}

install_apps() {
  local app
  for app in "${FLATPAK_APPS[@]}"; do
    if is_app_installed_user "$app"; then
      log "Already installed (--user): $app"
      summary_skip "$app"
      continue
    fi

    if ! is_app_in_catalog "$app"; then
      warn "ID no encontrado en Flathub (--user): $app"
      summary_fail "$app (does not exist in flathub --user)"
      continue
    fi

    log "Instalando (--user): $app"
    if run_or_print flatpak --user install -y --noninteractive flathub "$app"; then
      summary_ok "$app"
    else
      summary_fail "$app (install failed)"
    fi
  done
}

main() {
  ensure_flatpak

  remove_system_flathub_if_present
  ensure_user_flathub

  REMOTE_CATALOG=""
  load_remote_app_catalog

  install_apps

  summary_note "After installing user Flatpaks, close and reopen the graphical session so launchers appear (XDG_DATA_DIRS)."
  summary_note "Para revertir un Flatpak:    flatpak --user uninstall <app-id>"
  summary_note "Para revertir todos los user:flatpak --user uninstall --all"

  print_summary "Flatpaks (host, --user)" || true
}

main "$@"
