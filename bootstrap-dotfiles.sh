#!/usr/bin/env bash
# Clone (or update) this dotfiles repo and run a profile via Make + Ansible.
#
# Usage:
#   DOTFILES_REPO_URL="https://github.com/USUARIO/dotfiles.git" \
#   DOTFILES_DIR="$HOME/Projects/dotfiles" \
#   PROFILE="suse" \
#   bash bootstrap-dotfiles.sh
#
# Defaults:
#   DOTFILES_DIR=$HOME/Projects/dotfiles
#   PROFILE=suse
#   DOTFILES_REPO_URL=(required if directory does not exist)
set -Eeuo pipefail

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Projects/dotfiles}"
PROFILE="${PROFILE:-suse}"

case "$PROFILE" in
  suse) ;;
  *) echo "ERROR: PROFILE must be 'suse' (current: $PROFILE)" >&2; exit 1 ;;
esac

log() { printf '[bootstrap] %s\n' "$*"; }
die() { printf '[bootstrap] ERROR: %s\n' "$*" >&2; exit 1; }

is_opensuse() {
  [[ -r /etc/os-release ]] || return 1
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == opensuse* || "${ID_LIKE:-}" == *suse* ]]
}

install_opensuse_prereqs() {
  is_opensuse || return 0
  command -v zypper >/dev/null 2>&1 || return 0

  local missing=()
  for cmd in bash git make python3; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if command -v python3 >/dev/null 2>&1 && ! python3 -m venv --help >/dev/null 2>&1; then
    missing+=("python3-venv")
  fi

  if ((${#missing[@]} == 0)); then
    return 0
  fi

  log "Installing openSUSE bootstrap prerequisites: ${missing[*]}"
  if ((EUID == 0)); then
    zypper --non-interactive --gpg-auto-import-keys install --no-recommends \
      bash git make python3 python3-pip
  elif command -v sudo >/dev/null 2>&1; then
    sudo zypper --non-interactive --gpg-auto-import-keys install --no-recommends \
      bash git make python3 python3-pip
  else
    die "sudo is not available; install prerequisites as root: zypper install bash git make python3 python3-pip"
  fi
}

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
  install_opensuse_prereqs
  ensure_git
  ensure_make_python
  clone_or_update
  run_profile
}

main "$@"
