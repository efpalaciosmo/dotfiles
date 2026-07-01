#!/usr/bin/env bash
set -Eeuo pipefail

INSTALL=1
PRINT_SHELLENV=0
PRINT_PATH=0
INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

while (($#)); do
  case "$1" in
    --no-install) INSTALL=0 ;;
    --shellenv) PRINT_SHELLENV=1 ;;
    --path) PRINT_PATH=1 ;;
    *) printf '[homebrew] ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

log() { printf '[homebrew] %s\n' "$*" >&2; }
die() { printf '[homebrew] ERROR: %s\n' "$*" >&2; exit 1; }

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

install_homebrew() {
  log "Installing Homebrew with the official installer"
  if command -v curl >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL "$INSTALL_URL")" >&2
    return 0
  fi

  if command -v wget >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp)"
    wget -qO "$tmp" "$INSTALL_URL"
    /bin/bash "$tmp" >&2
    rm -f "$tmp"
    return 0
  fi

  die "curl or wget is required to download the Homebrew installer"
}

require_linux

brew_path="$(find_brew || true)"
if [[ -z "$brew_path" ]]; then
  if ((INSTALL == 0)); then
    die "Homebrew is not installed"
  fi
  install_homebrew
  brew_path="$(find_brew || true)"
fi

[[ -n "$brew_path" ]] || die "Homebrew was not found after installation"

if ((PRINT_PATH == 1)); then
  printf '%s\n' "$brew_path"
fi

if ((PRINT_SHELLENV == 1)); then
  "$brew_path" shellenv
  brew_prefix="$("$brew_path" --prefix)"
  for extra_path in \
    "$brew_prefix/opt/make/libexec/gnubin" \
    "$brew_prefix/opt/gnu-tar/libexec/gnubin" \
    "$brew_prefix/opt/llvm/bin" \
    "$brew_prefix/opt/ffmpeg-full/bin" \
    "$brew_prefix/opt/imagemagick-full/bin"; do
    if [[ -d "$extra_path" ]]; then
      printf 'export PATH="%s:$PATH";\n' "$extra_path"
    fi
  done
fi
