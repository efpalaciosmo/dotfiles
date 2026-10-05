#!/usr/bin/env bash
# Clone or update this repo, then install CachyOS packages and apply dotfiles.
set -Eeuo pipefail

DOTFILES_REPO_URL=${DOTFILES_REPO_URL:-}
DOTFILES_DIR=${DOTFILES_DIR:-$HOME/Projects/dotfiles}

log() { printf '[bootstrap] %s\n' "$*"; }
die() { printf '[bootstrap] ERROR: %s\n' "$*" >&2; exit 1; }

for command in git make; do
    command -v "$command" >/dev/null 2>&1 || die "$command is required for bootstrapping; install it first with sudo pacman -Syu --needed git make"
done

if [[ -d "$DOTFILES_DIR/.git" ]]; then
    log "Updating $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" pull --ff-only || die "update failed; resolve the repository manually"
elif [[ -e "$DOTFILES_DIR" ]]; then
    die "$DOTFILES_DIR exists but is not a Git repository"
else
    [[ -n "$DOTFILES_REPO_URL" ]] || die "DOTFILES_REPO_URL is required for a fresh clone"
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
fi

log "Installing CachyOS packages, fonts and dotfiles"
make -C "$DOTFILES_DIR" setup
