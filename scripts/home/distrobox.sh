#!/usr/bin/env bash
# scripts/home/distrobox.sh
# Install Distrobox locally (no sudo, no rpm-ostree) and create the
# `fedora` container with a custom $HOME, then bridge `podman` to the host.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

DISTROBOX_PREFIX="${DISTROBOX_PREFIX:-$HOME/.local}"
DISTROBOX_BIN="$DISTROBOX_PREFIX/bin/distrobox"
DISTROBOX_INSTALL_URL="${DISTROBOX_INSTALL_URL:-https://raw.githubusercontent.com/89luca89/distrobox/main/install}"

CONTAINER_NAME="${DISTROBOX_CONTAINER:-fedora}"
CONTAINER_IMAGE="${DISTROBOX_IMAGE:-quay.io/fedora/fedora:44-x86_64}"
CONTAINER_HOME="${DISTROBOX_CONTAINER_HOME:-$HOME/Projects/fedora}"

install_distrobox() {
  if [[ -x "$DISTROBOX_BIN" ]]; then
    log "Distrobox already installed at $DISTROBOX_BIN"
    summary_skip "Distrobox install ($DISTROBOX_PREFIX)"
    return 0
  fi

  ensure_dir "$DISTROBOX_PREFIX/bin"

  log "Instalando Distrobox en $DISTROBOX_PREFIX (sin sudo)"

  if has_cmd curl; then
    if is_dry_run; then
      printf '[DRY-RUN] curl -fsSL %s | sh -s -- --prefix %q\n' "$DISTROBOX_INSTALL_URL" "$DISTROBOX_PREFIX"
    else
      curl -fsSL "$DISTROBOX_INSTALL_URL" | sh -s -- --prefix "$DISTROBOX_PREFIX"
    fi
  elif has_cmd wget; then
    if is_dry_run; then
      printf '[DRY-RUN] wget -qO- %s | sh -s -- --prefix %q\n' "$DISTROBOX_INSTALL_URL" "$DISTROBOX_PREFIX"
    else
      wget -qO- "$DISTROBOX_INSTALL_URL" | sh -s -- --prefix "$DISTROBOX_PREFIX"
    fi
  else
    die "Need curl or wget to download the Distrobox installer"
  fi

  if ! is_dry_run; then
    if [[ ! -x "$DISTROBOX_BIN" ]]; then
      summary_fail "Distrobox install: $DISTROBOX_BIN does not exist after install"
      die "Distrobox was not installed at $DISTROBOX_BIN"
    fi
    log "Distrobox: $($DISTROBOX_BIN --version 2>/dev/null || echo unknown)"
  fi

  summary_ok "Distrobox installed at $DISTROBOX_PREFIX"
}

ensure_path() {
  ensure_path_line "$HOME/.profile" 'export PATH="$HOME/.local/bin:$PATH"'

  if [[ ":${PATH:-}:" != *":$HOME/.local/bin:"* ]]; then
    summary_note "For this session: export PATH=\"\$HOME/.local/bin:\$PATH\" (or restart the session)"
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

ensure_podman() {
  if has_cmd podman; then
    return 0
  fi
  summary_fail "podman is not available on the host (Silverblue without podman? rpm-ostree status)"
  die "Distrobox needs podman on the host. It should be included on Silverblue."
}

create_container() {
  ensure_dir "$CONTAINER_HOME"

  if is_dry_run; then
    printf '[DRY-RUN] %q list --no-color | grep -q %q || %q create --name %q --image %q --home %q --yes\n' \
      "$DISTROBOX_BIN" "$CONTAINER_NAME" \
      "$DISTROBOX_BIN" "$CONTAINER_NAME" "$CONTAINER_IMAGE" "$CONTAINER_HOME"
    summary_ok "Contenedor $CONTAINER_NAME (dry-run)"
    return 0
  fi

  if "$DISTROBOX_BIN" list --no-color 2>/dev/null | awk '{print $3}' | grep -Fxq "$CONTAINER_NAME"; then
    log "Distrobox container '$CONTAINER_NAME' already exists; not recreating it."
    summary_skip "Contenedor $CONTAINER_NAME"
    summary_note "Para recrearlo:  distrobox rm $CONTAINER_NAME && make distrobox"
    return 0
  fi

  log "Creating distrobox container '$CONTAINER_NAME' with image '$CONTAINER_IMAGE'"
  log "Home custom: $CONTAINER_HOME"

  if "$DISTROBOX_BIN" create \
      --name "$CONTAINER_NAME" \
      --image "$CONTAINER_IMAGE" \
      --home "$CONTAINER_HOME" \
      --yes; then
    summary_ok "Contenedor $CONTAINER_NAME creado"
  else
    summary_fail "distrobox create failed for $CONTAINER_NAME"
    die "Could not create container $CONTAINER_NAME"
  fi
}

bridge_podman_inside_container() {
  if is_dry_run; then
    printf '[DRY-RUN] %q enter %q -- sudo ln -sfn /usr/bin/distrobox-host-exec /usr/local/bin/podman\n' \
      "$DISTROBOX_BIN" "$CONTAINER_NAME"
    return 0
  fi

  log "Linking podman inside the container to distrobox-host-exec"
  if "$DISTROBOX_BIN" enter "$CONTAINER_NAME" -- \
      sudo ln -sfn /usr/bin/distrobox-host-exec /usr/local/bin/podman; then
    summary_ok "podman -> distrobox-host-exec (inside $CONTAINER_NAME)"
  else
    summary_fail "Could not link podman inside the container; run manually:"
    summary_note "distrobox enter $CONTAINER_NAME -- sudo ln -sfn /usr/bin/distrobox-host-exec /usr/local/bin/podman"
    return 0
  fi

  if ! "$DISTROBOX_BIN" enter "$CONTAINER_NAME" -- podman version >/dev/null 2>&1; then
    summary_fail "podman inside the container does not respond."
    summary_note "If it fails with 'host-spawn': close and reopen the container with 'distrobox stop $CONTAINER_NAME && distrobox enter $CONTAINER_NAME'"
  else
    summary_ok "podman inside the container works via distrobox-host-exec"
  fi
}

main() {
  if is_ostree_host; then
    log "Detectado host ostree/atomic (OK para Fedora Silverblue)"
  else
    warn "The host does not look ostree/atomic. Continuing because it may be another Linux distro."
  fi

  ensure_podman
  install_distrobox
  ensure_path
  create_container
  bridge_podman_inside_container

  print_summary "Distrobox (host)" || true
}

main "$@"
