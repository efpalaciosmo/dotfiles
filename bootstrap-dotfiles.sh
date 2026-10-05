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

log() { printf '[bootstrap] %s\n' "$*"; }
die() {
	printf '[bootstrap] ERROR: %s\n' "$*" >&2
	exit 1
}

require_fedora() {
	[[ -r /etc/os-release ]] || die "/etc/os-release is missing"
	# shellcheck disable=SC1091
	source /etc/os-release
	[[ "${ID:-}" == "fedora" &&
		("${VARIANT_ID:-}" == "workstation" || "${VARIANT_ID:-}" == "container") ]] ||
		die "This setup requires Fedora Workstation or Container Image."
}

ensure_bootstrap_tools() {
	local packages=()
	command -v git >/dev/null 2>&1 || packages+=("git")
	command -v make >/dev/null 2>&1 || packages+=("make")
	command -v python3.14 >/dev/null 2>&1 || packages+=("python3.14")

	if ((${#packages[@]} > 0)); then
		log "Installing bootstrap packages with dnf: ${packages[*]}"
		if ((EUID == 0)); then
			dnf install -y "${packages[@]}"
		else
			sudo -n true || die "sudo cannot elevate privileges here. Run bootstrap from a normal Fedora Distrobox terminal with working sudo."
			sudo -n dnf install -y "${packages[@]}"
		fi
	fi

	command -v git >/dev/null 2>&1 || die "git is unavailable after dnf bootstrap"
	command -v make >/dev/null 2>&1 || die "make is unavailable after dnf bootstrap"
	command -v python3.14 >/dev/null 2>&1 || die "python3.14 is unavailable after dnf bootstrap"
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
	require_fedora
	ensure_bootstrap_tools
	clone_or_update
	run_make
}

main "$@"
