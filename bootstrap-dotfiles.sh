#!/usr/bin/env bash
# Clone (or update) this dotfiles repo and run a profile via Make + Ansible.
#
# Usage:
#   DOTFILES_REPO_URL="https://github.com/USUARIO/dotfiles.git" \
#   DOTFILES_DIR="$HOME/Projects/dotfiles" \
#   PROFILE="tw-vm" \
#   bash bootstrap-dotfiles.sh
#
# Defaults:
#   DOTFILES_DIR=$HOME/Projects/dotfiles
#   PROFILE=tw-vm
#   DOTFILES_REPO_URL=(required if directory does not exist)
set -Eeuo pipefail

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Projects/dotfiles}"
PROFILE="${PROFILE:-tw-vm}"

case "$PROFILE" in
  tw-vm|arch) ;;
  home) PROFILE=tw-vm ;;
  vm) PROFILE=tw-vm ;;
  *) echo "ERROR: PROFILE must be 'tw-vm' or 'arch' (current: $PROFILE)" >&2; exit 1 ;;
esac

log() { printf '[bootstrap] %s\n' "$*"; }
die() { printf '[bootstrap] ERROR: %s\n' "$*" >&2; exit 1; }

ensure_git() {
  command -v git >/dev/null 2>&1 || die "git is not available"
}

ensure_make_python() {
  command -v make >/dev/null 2>&1 || die "make is not available"
  command -v python3 >/dev/null 2>&1 || die "python3 is not available"
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
  log "Running: make setup && make $PROFILE"
  cd "$DOTFILES_DIR"
  make setup
  make "$PROFILE"
}

main() {
  ensure_git
  ensure_make_python
  clone_or_update
  run_profile
}

main "$@"
