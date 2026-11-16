#!/bin/bash
# Bash 3.2-compatible entry point; prerequisites are deliberately installed manually.
set -euo pipefail
DOTFILES_DIR=${DOTFILES_DIR:-$HOME/Projects/dotfiles_mac}
DOTFILES_REPO_URL=${DOTFILES_REPO_URL:-}
DOTFILES_BRANCH=${DOTFILES_BRANCH:-}
DOTFILES_UPDATE=${DOTFILES_UPDATE:-0}
DRY_RUN=${DRY_RUN:-0}
die() { printf '[bootstrap] %s\n' "$*" >&2; exit 1; }
run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '[dry-run]'; printf ' %q' "$@"; printf '\n'
  else "$@"; fi
}
[[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] ||
  die 'Use native Apple Silicon macOS, not Rosetta.'
[[ $EUID != 0 ]] || die 'Do not run bootstrap with sudo.'
xcode-select -p >/dev/null 2>&1 || die 'Run xcode-select --install, then wait for completion.'
[[ -x /opt/homebrew/bin/brew ]] ||
  die 'Install Homebrew first: https://docs.brew.sh/Installation'
eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -x /opt/homebrew/bin/bash ]] || die 'Run brew install bash first.'
/opt/homebrew/bin/bash -c '((BASH_VERSINFO[0] >= 5))' || die 'Bash 5+ is required.'
command -v git >/dev/null || die 'Git is required.'
command -v make >/dev/null || die 'Apple Make from Command Line Tools is required.'
if [[ -e $DOTFILES_DIR || -L $DOTFILES_DIR ]]; then
  [[ -d $DOTFILES_DIR/.git || -f $DOTFILES_DIR/.git ]] || die 'Destination exists but is not a checkout.'
  if [[ -n $DOTFILES_BRANCH ]]; then
    [[ $(git -C "$DOTFILES_DIR" branch --show-current) == "$DOTFILES_BRANCH" ]] ||
      die 'Existing branch differs; switch it manually after reviewing local work.'
  fi
  if [[ $DOTFILES_UPDATE == 1 ]]; then
    [[ -z $(git -C "$DOTFILES_DIR" status --porcelain) ]] ||
      die 'Refusing to update a dirty checkout (including untracked files).'
    run git -C "$DOTFILES_DIR" pull --ff-only
  fi
else
  [[ -n $DOTFILES_REPO_URL && -n $DOTFILES_BRANCH ]] ||
    die 'Set DOTFILES_REPO_URL and DOTFILES_BRANCH explicitly for a fresh clone.'
  run mkdir -p "$(dirname "$DOTFILES_DIR")"
  run git clone --branch "$DOTFILES_BRANCH" --single-branch -- "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
fi
run make -C "$DOTFILES_DIR" setup
