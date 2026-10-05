#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
failures=0

check_command() {
    if command -v "$1" >/dev/null 2>&1; then printf 'OK   command %s -> %s\n' "$1" "$(command -v "$1")"
    else printf 'MISS command %s\n' "$1" >&2; failures=$((failures + 1)); fi
}

for command in stow niri waybar fuzzel kitty vim zsh starship mako swaybg swaylock swayidle wl-copy wl-paste playerctl brightnessctl notify-send wpctl nmcli nm-connection-editor bluetoothctl rfkill ip cal lsblk pgrep systemctl loginctl python3 xdg-open podman distrobox epiphany flatpak virsh timeout tailscale tailscaled; do
    check_command "$command"
done

check_unit() {
    local scope=$1 unit=$2 start_now=$3
    local -a scope_args=()
    [[ $scope == user ]] && scope_args=(--user)
    if systemctl "${scope_args[@]}" is-enabled --quiet "$unit"; then
        printf 'OK   %s unit enabled: %s\n' "$scope" "$unit"
    else
        printf 'MISS %s unit disabled: %s (run make services)\n' "$scope" "$unit" >&2
        failures=$((failures + 1))
    fi
    if [[ $start_now == yes ]]; then
        if systemctl "${scope_args[@]}" is-active --quiet "$unit"; then
            printf 'OK   %s unit active: %s\n' "$scope" "$unit"
        else
            printf 'MISS %s unit inactive: %s (run make services; inspect systemctl %s status %s)\n' \
                "$scope" "$unit" "${scope_args[*]}" "$unit" >&2
            failures=$((failures + 1))
        fi
    fi
}

if command -v systemctl >/dev/null 2>&1; then
    check_unit system gdm.service no
    for unit in NetworkManager.service bluetooth.service tailscaled.service virtqemud.socket virtinterfaced.socket virtnetworkd.socket virtnodedevd.socket virtnwfilterd.socket virtsecretd.socket virtstoraged.socket virtproxyd.socket virtlogd.socket virtlockd.socket; do
        check_unit system "$unit" yes
    done
    for unit in pipewire.socket pipewire-pulse.socket wireplumber.service podman.socket; do
        check_unit user "$unit" yes
    done

    if command -v bluetoothctl >/dev/null 2>&1 && systemctl is-active --quiet bluetooth.service; then
        controller=$(bluetoothctl --timeout 5 show 2>/dev/null || true)
        if [[ $controller == Controller\ * ]]; then
            printf 'OK   Bluetooth adapter detected\n'
            if [[ $controller == *'Powered: yes'* ]]; then
                printf 'OK   Bluetooth adapter powered on\n'
            else
                printf 'INFO Bluetooth adapter powered off (enable it in the Bluetooth menu)\n'
            fi
        else
            printf 'MISS Bluetooth adapter (inspect rfkill list bluetooth and journalctl -b -u bluetooth)\n' >&2
            failures=$((failures + 1))
        fi
    fi
fi
if command -v virsh >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1; then
    for query in list net-list pool-list; do
        if result=$(timeout 15 virsh --readonly --connect qemu:///system "$query" --all 2>&1); then
            printf 'OK   libvirt qemu:///system %s\n' "$query"
        else
            printf 'MISS libvirt qemu:///system %s (run make libvirt): %s\n' "$query" "$result" >&2
            failures=$((failures + 1))
        fi
    done
fi
if command -v rfkill >/dev/null 2>&1; then
    if radio_state=$(rfkill --noheadings --output SOFT,HARD list bluetooth 2>/dev/null); then
        if [[ $radio_state =~ (^|[[:space:]])blocked($|[[:space:]]) ]]; then
            printf 'MISS Bluetooth radio blocked (soft: rfkill unblock bluetooth; hard: physical switch/airplane mode)\n' >&2
            failures=$((failures + 1))
        fi
    else
        printf 'MISS Bluetooth rfkill status could not be read\n' >&2
        failures=$((failures + 1))
    fi
fi

if command -v flatpak >/dev/null 2>&1; then
    if flatpak remotes --user --columns=name | grep -qx flathub; then
        printf 'OK   user Flathub remote\n'
    else
        printf 'MISS user Flathub remote (run make packages)\n' >&2
        failures=$((failures + 1))
    fi
    if flatpak remotes --system --columns=name | grep -qx flathub; then
        printf 'MISS system Flathub remote still configured (run make packages)\n' >&2
        failures=$((failures + 1))
    fi
fi

if [[ -r /etc/pam.d/swaylock ]]; then
    printf 'OK   swaylock PAM configuration\n'
else
    printf 'MISS /etc/pam.d/swaylock (reinstall the official swaylock package)\n' >&2
    failures=$((failures + 1))
fi

for relative in niri/scripts/lock-screen niri/scripts/session-idle; do
    if [[ -x $HOME/.config/$relative ]]; then
        printf 'OK   executable ~/.config/%s\n' "$relative"
    else
        printf 'MISS executable ~/.config/%s (run make dotfiles)\n' "$relative" >&2
        failures=$((failures + 1))
    fi
done

wallpaper=$HOME/.config/niri/backgrounds/bluesky.png
if [[ -s $wallpaper ]]; then
    printf 'OK   wallpaper %s -> %s\n' "$wallpaper" "$(readlink -f -- "$wallpaper")"
else
    printf 'MISS wallpaper %s\n' "$wallpaper" >&2
    failures=$((failures + 1))
fi

desktop=${XDG_CURRENT_DESKTOP:-}
if [[ ${desktop,,} == *niri* && -n ${WAYLAND_DISPLAY:-} ]] &&
    command -v pgrep >/dev/null 2>&1; then
    if pgrep -u "$(id -u)" -x swayidle >/dev/null; then
        printf 'OK   swayidle is running\n'
    else
        printf 'MISS swayidle is not running (install swayidle, link dotfiles, then log out and back in)\n' >&2
        failures=$((failures + 1))
    fi
fi
if [[ -x /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]]; then
    printf 'OK   polkit-gnome agent\n'
else
    printf 'MISS polkit-gnome agent\n' >&2
    failures=$((failures + 1))
fi

if command -v niri >/dev/null 2>&1; then niri validate || failures=$((failures + 1)); fi
if command -v fuzzel >/dev/null 2>&1; then fuzzel --check-config --config="$HOME/.config/fuzzel/fuzzel.ini" || failures=$((failures + 1)); fi

for package in "$@"; do
    while IFS= read -r -d '' source; do
        relative=${source#"$repo_root/packages/$package/"}
        target=$HOME/$relative
        if [[ -L "$target" && -e "$target" ]]; then
            if [[ $(readlink -f -- "$target") != $(readlink -f -- "$source") ]]; then
                printf 'WRONG  %s -> %s (expected %s)\n' \
                    "$target" "$(readlink -- "$target")" "$source" >&2
                failures=$((failures + 1))
            fi
        elif [[ -L "$target" ]]; then printf 'BROKEN %s\n' "$target" >&2; failures=$((failures + 1))
        elif [[ -e "$target" ]]; then printf 'FILE   %s (expected symlink)\n' "$target" >&2; failures=$((failures + 1))
        else printf 'MISS   %s\n' "$target" >&2; failures=$((failures + 1)); fi
    done < <(find "$repo_root/packages/$package" -type f ! -iname 'README' ! -iname 'README.*' -print0)
done

if ((failures > 0)); then printf 'doctor: %d problem(s) found\n' "$failures" >&2; exit 1; fi
printf 'doctor: OK\n'
