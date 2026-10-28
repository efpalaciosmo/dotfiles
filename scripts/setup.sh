#!/usr/bin/env bash
# One user-facing entry point; root is used only for the installation subprocess.
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
((EUID != 0)) || {
    printf 'setup: run make setup as your normal user; sudo is requested when needed\n' >&2
    exit 1
}
if (($#)); then
    printf 'setup: no arguments are needed or accepted; run make setup\n' >&2
    exit 1
fi

# os-release belongs to the installed distribution, not to this repository.
# shellcheck source=/dev/null
source /etc/os-release
if [[ ${ID:-} != cachyos && ! ( ${ID:-} == arch && -f /etc/cachyos-release ) ]]; then
    exec make --no-print-directory -C "$repo_root" local
fi

if [[ -d /run/archiso || -d /run/miso ]] || systemd-detect-virt --quiet --container; then
    printf 'setup: use the installed CachyOS host, not a live installer or container\n' >&2
    exit 1
fi

command -v sudo >/dev/null 2>&1 || {
    printf 'setup: the minimal installation must include sudo configured for your account\n' >&2
    exit 1
}

if ! command -v python3 >/dev/null 2>&1; then
    [[ -t 0 ]] || { printf 'setup: Python bootstrap requires an interactive terminal\n' >&2; exit 1; }
    # Validate effective signature policy before even the prerequisite upgrade.
    pacman -Q cachyos-keyring >/dev/null
    mapfile -t repos < <(pacman-conf --repo-list)
    ((${#repos[@]})) || { printf 'setup: no configured repositories\n' >&2; exit 1; }
    for repo in '' "${repos[@]}"; do
        if [[ -n $repo ]]; then
            policy=$(pacman-conf --repo "$repo" SigLevel)
        else
            policy=$(pacman-conf SigLevel)
        fi
        required=false
        read -r -a tokens <<< "${policy//$'\n'/ }"
        for token in "${tokens[@]}"; do
            case $token in
                Required|PackageRequired) required=true ;;
                Never|Optional|PackageNever|PackageOptional|TrustAll|PackageTrustAll)
                    printf 'setup: refusing insecure package-signature policy: %s\n' "$policy" >&2
                    exit 1 ;;
            esac
        done
        "$required" || { printf 'setup: package signatures must be required\n' >&2; exit 1; }
    done
    printf '%s\n' 'Python is needed for the installer. Bootstrap plan: sudo pacman -Syu --needed python'
    printf '%s\n' 'This is a full system upgrade. Proceed only with tested external backups, rescue and fallback boot.'
    read -r -p 'Type INSTALL to confirm these recovery preparations and bootstrap Python: ' confirmation
    [[ $confirmation == INSTALL ]] || { printf 'setup: cancelled; no bootstrap changes\n' >&2; exit 1; }
    # Preserve the pre-upgrade inventory even when Python is not yet available.
    bootstrap_state=${XDG_STATE_HOME:-$HOME/.local/state}/cachyos-desktop
    (
        umask 077
        mkdir -p -- "$bootstrap_state"
        record=$(mktemp "$bootstrap_state/bootstrap-before-XXXXXXXX.txt")
        {
            uname -r
            pacman -Q
            systemctl list-unit-files --state=enabled --no-pager
        } > "$record"
        printf 'setup: prerequisite-upgrade inventory: %s\n' "$record"
    )
    sudo pacman -Syu --needed python
fi

make --no-print-directory -C "$repo_root" check
python3 "$repo_root/scripts/cachyos.py" setup
# Validate again now that the desktop-specific validators are available.
make --no-print-directory -C "$repo_root" check
