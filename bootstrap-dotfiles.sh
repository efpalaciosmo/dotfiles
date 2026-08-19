#!/usr/bin/env bash
# Clone or update this repo and apply fonts and dotfiles. It installs no packages.
set -Eeuo pipefail

DOTFILES_REPO_URL=${DOTFILES_REPO_URL:-}
DOTFILES_DIR=${DOTFILES_DIR:-$HOME/Projects/dotfiles}

log() { printf '[bootstrap] %s\n' "$*"; }
die() { printf '[bootstrap] ERROR: %s\n' "$*" >&2; exit 1; }

for command in git make stow curl tar unzip fc-cache; do
    command -v "$command" >/dev/null 2>&1 || die "$command is required; install it from Fedora first"
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

log "Installing fonts and linking dotfiles"
make -C "$DOTFILES_DIR" setup
