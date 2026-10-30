#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
failures=0
pending=0

check_command() {
    if command -v "$1" >/dev/null 2>&1; then printf 'OK   command %s -> %s\n' "$1" "$(command -v "$1")"
    else printf 'MISS command %s\n' "$1" >&2; failures=$((failures + 1)); fi
}

for command in stow niri waybar fuzzel ghostty xdg-terminal-exec vim zsh starship mako swaybg swaylock swayidle wl-copy wl-paste playerctl notify-send wpctl nmcli nm-connection-editor bluetoothctl rfkill ip cal lsblk pgrep systemctl loginctl python3 xdg-open xdg-mime gsettings busctl; do
    check_command "$command"
done

# Read-only runtime checks; services are managed through the distribution.
if command -v systemctl >/dev/null 2>&1; then
    for unit in NetworkManager.service bluetooth.service; do
        if [[ $unit == bluetooth.service ]] && ! compgen -G '/sys/class/bluetooth/hci*' >/dev/null; then
            printf 'INFO optional Bluetooth adapter absent; service not required\n'
            continue
        fi
        if systemctl is-active --quiet "$unit"; then
            printf 'OK   desktop service active: %s\n' "$unit"
        else
            printf 'MISS desktop service inactive: %s (inspect systemctl status %s in your distribution)\n' "$unit" "$unit" >&2
            failures=$((failures + 1))
        fi
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
            printf 'INFO optional Bluetooth adapter absent\n'
        fi
    fi
fi
if command -v python3 >/dev/null 2>&1; then
    result=0
    python3 "$repo_root/scripts/desktop-check.py" || result=$?
    case $result in
        3) failures=$((failures + 1)); pending=$((pending + 1)) ;;
        2) pending=$((pending + 1)) ;;
        0) ;;
        *) failures=$((failures + 1)) ;;
    esac
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

pam_config=
for candidate in /etc/pam.d/swaylock /usr/lib/pam.d/swaylock; do
    if [[ -e $candidate ]]; then pam_config=$candidate; break; fi
done
if [[ -n $pam_config && -r $pam_config ]]; then
    printf 'OK   swaylock PAM configuration\n'
else
    printf 'MISS swaylock PAM configuration under /etc/pam.d or /usr/lib/pam.d (reinstall the official swaylock package)\n' >&2
    failures=$((failures + 1))
fi

for relative in niri/scripts/lock-screen niri/scripts/session-idle; do
    if [[ -x $HOME/.config/$relative ]]; then
        printf 'OK   executable ~/.config/%s\n' "$relative"
    else
        printf 'MISS executable ~/.config/%s (run make)\n' "$relative" >&2
        failures=$((failures + 1))
    fi
done

wallpaper=$HOME/.config/niri/backgrounds/adwaita-dark.png
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
polkit_agent=/usr/libexec/kf6/polkit-kde-authentication-agent-1
if [[ -x $polkit_agent ]]; then
    printf 'OK   KDE polkit agent\n'
else
    printf 'MISS KDE polkit agent (%s)\n' "$polkit_agent" >&2
    failures=$((failures + 1))
fi

if command -v niri >/dev/null 2>&1; then niri validate || failures=$((failures + 1)); fi
if command -v fuzzel >/dev/null 2>&1; then fuzzel --check-config --log-no-syslog --config="$HOME/.config/fuzzel/fuzzel.ini" || failures=$((failures + 1)); fi
if command -v ghostty >/dev/null 2>&1; then
    # Validate the effective configuration, including automatically loaded files.
    ghostty +validate-config || failures=$((failures + 1))
fi
if command -v locale >/dev/null 2>&1 && ! locale -a | grep -Eiq '^en_US\.(utf8|utf-8)$'; then
    printf 'MISS en_US.UTF-8 locale (provide it through your distribution)\n' >&2
    failures=$((failures + 1))
fi

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
    done < <(find "$repo_root/packages/$package" -type d -name __pycache__ -prune -o \
        -type f ! -iname 'README' ! -iname 'README.*' ! -name '*.pyc' ! -name '*.pyo' -print0)
done

if ((failures > 0)); then printf 'doctor: %d missing/failed requirement(s), %d pending check group(s)\n' "$failures" "$pending" >&2; exit 1; fi
if ((pending > 0)); then printf 'doctor: %d pending re-login/session check group(s)\n' "$pending"; exit 2; fi
printf 'doctor: OK\n'
