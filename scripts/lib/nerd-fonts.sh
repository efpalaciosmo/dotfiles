#!/usr/bin/env bash
# scripts/lib/nerd-fonts.sh
# Idempotent installer for a fixed set of Nerd Fonts in user space.
# Source from scripts/home/fonts.sh and scripts/vm/fonts.sh.

set -Eeuo pipefail

# shellcheck source=./common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

NERD_FONTS_VERSION="${NERD_FONTS_VERSION:-v3.4.0}"
NERD_FONTS_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}"

# Map archive name -> install subdirectory under $HOME/.local/share/fonts/nerd-fonts
NERD_FONTS_LIST=(
  "IBMPlexMono.tar.xz:IBMPlexMono"
  "JetBrainsMono.tar.xz:JetBrainsMono"
)

NERD_FONTS_ROOT="$HOME/.local/share/fonts/nerd-fonts"
NERD_FONTS_DOWNLOAD_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/nerd-fonts/${NERD_FONTS_VERSION}"

install_nerd_fonts() {
  ensure_dir "$NERD_FONTS_ROOT"
  ensure_dir "$NERD_FONTS_DOWNLOAD_DIR"

  if ! has_cmd tar; then
    die "tar es requerido para instalar las Nerd Fonts"
  fi

  local entry archive subdir url archive_path target marker
  for entry in "${NERD_FONTS_LIST[@]}"; do
    archive="${entry%%:*}"
    subdir="${entry##*:}"
    url="${NERD_FONTS_BASE_URL}/${archive}"
    archive_path="${NERD_FONTS_DOWNLOAD_DIR}/${archive}"
    target="${NERD_FONTS_ROOT}/${subdir}"
    marker="${target}/.dotfiles-installed-${NERD_FONTS_VERSION}"

    if [[ -f "$marker" ]]; then
      log "Nerd Font already installed: ${subdir} (${NERD_FONTS_VERSION})"
      summary_skip "Nerd Font ${subdir} ${NERD_FONTS_VERSION}"
      continue
    fi

    log "Instalando Nerd Font ${subdir} ${NERD_FONTS_VERSION}"

    download "$url" "$archive_path"

    ensure_dir "$target"

    if ! is_dry_run; then
      if ! tar -xJf "$archive_path" -C "$target"; then
        warn "Could not extract ${archive_path}; cleaning up and retrying"
        rm -rf "${target:?}"/*
        if ! tar -xJf "$archive_path" -C "$target"; then
          summary_fail "Nerd Font ${subdir}: extraction failed"
          continue
        fi
      fi
      touch "$marker"
    else
      printf '[DRY-RUN] tar -xJf %q -C %q\n' "$archive_path" "$target"
      printf '[DRY-RUN] touch %q\n' "$marker"
    fi
    summary_ok "Nerd Font ${subdir} ${NERD_FONTS_VERSION}"
  done

  fc_cache_dir "$HOME/.local/share/fonts"
}
