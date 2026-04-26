#!/usr/bin/env bash
# scripts/bootstrap-dotfiles.sh
# Clone (or update) this dotfiles repo and run a profile.
#
# Usage:
#   DOTFILES_REPO_URL="https://github.com/USUARIO/dotfiles.git" \
#   DOTFILES_DIR="$HOME/Projects/dotfiles" \
#   PROFILE="home" \
#   bash scripts/bootstrap-dotfiles.sh
#
# Defaults:
#   DOTFILES_DIR=$HOME/Projects/dotfiles
#   PROFILE=home
#   DOTFILES_REPO_URL=(no default; required if directory does not exist)
set -Eeuo pipefail

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Projects/dotfiles}"
PROFILE="${PROFILE:-home}"

case "$PROFILE" in
  home|vm) ;;
  *) echo "ERROR: PROFILE must be 'home' or 'vm' (current: $PROFILE)" >&2; exit 1 ;;
esac

log() { printf '[bootstrap] %s\n' "$*"; }
die() { printf '[bootstrap] ERROR: %s\n' "$*" >&2; exit 1; }

ensure_git() {
  command -v git >/dev/null 2>&1 || die "git is not available"
}

ensure_make() {
  command -v make >/dev/null 2>&1 || die "make is not available"
}

clone_or_update() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    log "Updating $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" fetch --prune
    if ! git -C "$DOTFILES_DIR" pull --ff-only; then
      die "git pull --ff-only failed. Resolve it manually and try again."
    fi
    return 0
  fi

  if [[ -d "$DOTFILES_DIR" ]]; then
    die "$DOTFILES_DIR exists but is NOT a git repo. Move or delete that directory."
  fi

  if [[ -z "$DOTFILES_REPO_URL" ]]; then
    die "DOTFILES_DIR does not exist and DOTFILES_REPO_URL is not set."
  fi

  log "Cloning $DOTFILES_REPO_URL into $DOTFILES_DIR"
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
}

run_profile() {
  log "Ejecutando: make $PROFILE"
  cd "$DOTFILES_DIR"
  make "$PROFILE"
}

main() {
  ensure_git
  ensure_make
  clone_or_update
  run_profile
}

main "$@"
