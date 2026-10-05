#!/usr/bin/env bash
# Install the declared packages only on CachyOS. Never modify repositories.
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
manifest=$repo_root/system-packages/cachyos.txt

die() { printf 'packages: ERROR: %s\n' "$*" >&2; return 1; }

is_cachyos() {
    [[ -r /etc/os-release ]] && grep -Eq '^ID="?cachyos"?$' /etc/os-release
}

load_packages() {
    local name
    packages=()
    [[ -r $manifest ]] || { die "manifest not found: $manifest"; return 1; }
    while IFS= read -r name || [[ -n $name ]]; do
        [[ -z $name || $name == \#* ]] && continue
        [[ $name =~ ^[a-z0-9][a-z0-9@._+-]*$ ]] || {
            die "invalid package name in $manifest: $name"
            return 1
        }
        packages+=("$name")
    done < "$manifest"
    ((${#packages[@]} > 0)) || { die "empty package manifest: $manifest"; return 1; }
}

main() {
    ((EUID != 0)) || { die 'run make setup as your normal user, not root'; return 1; }
    is_cachyos || { die 'make setup installs packages only on CachyOS; use make local for dotfiles without system packages'; return 1; }
    command -v pacman >/dev/null 2>&1 || { die 'pacman is required'; return 1; }
    command -v sudo >/dev/null 2>&1 || { die 'sudo is required'; return 1; }
    load_packages || return 1

    printf 'packages: full system update and %d declared packages (including stow)\n' "${#packages[@]}" >&2
    sudo pacman -Syu --needed "${packages[@]}"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
