#!/usr/bin/env bash
# Clone or update this dotfiles repo and run the Fedora Make flow.
#
# Usage:
#   DOTFILES_REPO_URL="https://github.com/USER/dotfiles.git" \
#   DOTFILES_DIR="$HOME/Projects/dotfiles" \
#   bash bootstrap-dotfiles.sh
#
# Defaults:
#   DOTFILES_DIR=$HOME/Projects/dotfiles
#   DOTFILES_REPO_URL is required when DOTFILES_DIR does not exist.
set -Eeuo pipefail

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Projects/dotfiles}"
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

log() { printf '[bootstrap] %s\n' "$*"; }
die() { printf '[bootstrap] ERROR: %s\n' "$*" >&2; exit 1; }

require_linux() {
  [[ "$(uname -s)" == "Linux" ]] || die "This dotfiles setup is Linux-only (Fedora Silverblue)."
}

find_brew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi

  for candidate in \
    /home/linuxbrew/.linuxbrew/bin/brew \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

load_homebrew() {
  local brew_path
  brew_path="$(find_brew)" || return 1
  eval "$(HOMEBREW_NO_AUTO_UPDATE=1 "$brew_path" shellenv)"

  local brew_prefix
  brew_prefix="$(HOMEBREW_NO_AUTO_UPDATE=1 "$brew_path" --prefix)"
  for extra_path in \
    "$brew_prefix/opt/make/libexec/gnubin" \
    "$brew_prefix/opt/gnu-tar/libexec/gnubin" \
    "$brew_prefix/opt/llvm/bin" \
    "$brew_prefix/opt/ffmpeg-full/bin" \
    "$brew_prefix/opt/imagemagick-full/bin"; do
    if [[ -d "$extra_path" ]]; then
      export PATH="$extra_path:$PATH"
    fi
  done
}

install_homebrew() {
  log "Installing Homebrew with the official installer"
  if command -v curl >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_URL")"
    return 0
  fi

  if command -v wget >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp)"
    wget -qO "$tmp" "$HOMEBREW_INSTALL_URL"
    /bin/bash "$tmp"
    rm -f "$tmp"
    return 0
  fi

  die "curl or wget is required to download the Homebrew installer"
}

ensure_homebrew() {
  if load_homebrew; then
    return 0
  fi

  install_homebrew
  load_homebrew || die "Homebrew was installed but could not be loaded"
}

ensure_bootstrap_tools() {
  ensure_homebrew

  local formulas=()
  command -v git >/dev/null 2>&1 || formulas+=("git")
  command -v make >/dev/null 2>&1 || formulas+=("make")
  command -v python3 >/dev/null 2>&1 || formulas+=("python")

  if ((${#formulas[@]} > 0)); then
    log "Installing bootstrap tools with Homebrew: ${formulas[*]}"
    brew install "${formulas[@]}"
    load_homebrew || true
  fi

  command -v git >/dev/null 2>&1 || die "git is not available after Homebrew bootstrap"
  command -v make >/dev/null 2>&1 || die "make is not available after Homebrew bootstrap"
  command -v python3 >/dev/null 2>&1 || die "python3 is not available after Homebrew bootstrap"
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
    die "$DOTFILES_DIR exists but is not a git repo. Move it and try again."
  fi

  if [[ -z "$DOTFILES_REPO_URL" ]]; then
    die "DOTFILES_DIR does not exist and DOTFILES_REPO_URL is not set."
  fi

  log "Cloning $DOTFILES_REPO_URL into $DOTFILES_DIR"
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
}

run_make() {
  log "Running make"
  cd "$DOTFILES_DIR"
  make
}

main() {
  require_linux
  ensure_bootstrap_tools
  clone_or_update
  run_make
}

main "$@"
