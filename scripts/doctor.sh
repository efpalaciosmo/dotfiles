#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
failures=0

check_command() {
    if command -v "$1" >/dev/null 2>&1; then printf 'OK   command %s -> %s\n' "$1" "$(command -v "$1")"
    else printf 'MISS command %s\n' "$1" >&2; failures=$((failures + 1)); fi
}

for command in stow niri waybar rofi ghostty mako swaybg swaylock wl-copy wl-paste cliphist playerctl brightnessctl notify-send wpctl nmcli ip cal lsblk systemctl loginctl dbus-update-activation-environment; do
    check_command "$command"
done

if command -v niri >/dev/null 2>&1; then niri validate || failures=$((failures + 1)); fi
if command -v rofi >/dev/null 2>&1; then rofi -rasi-validate "$HOME/.config/rofi/config.rasi" || failures=$((failures + 1)); fi
if command -v ghostty >/dev/null 2>&1; then ghostty +validate-config || failures=$((failures + 1)); fi

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
