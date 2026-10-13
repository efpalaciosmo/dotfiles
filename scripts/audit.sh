#!/usr/bin/env bash
# Deliberately read-only; missing tools and inaccessible files are reported.
set -uo pipefail
inspect() {
    printf '\nAUDIT %s\n' "$*"
    if command -v "$1" >/dev/null 2>&1; then
        timeout 20 "$@" 2>&1 || printf 'INFO unavailable or failed (status %s)\n' "$?"
    else
        printf 'INFO command not installed: %s\n' "$1"
    fi
}
inspect cat /etc/os-release
inspect uname -a
inspect lscpu
inspect lspci -nnk
inspect lsblk -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINTS
inspect findmnt --fstab
inspect findmnt -R /boot
inspect findmnt -R /efi
inspect bootctl status --no-pager
inspect efibootmgr -v
inspect mokutil --sb-state
inspect sbctl status
inspect cat /proc/cmdline
inspect cat /etc/mkinitcpio.conf
inspect ls /etc/mkinitcpio.conf.d /etc/mkinitcpio.d /etc/dracut.conf.d /etc/kernel /etc/pacman.d/hooks
inspect cat /boot/loader/loader.conf /boot/limine.conf /etc/default/grub
inspect ls -l /boot /efi /boot/efi
inspect pacman -Q
inspect pacman -Qm
inspect chwd --list-installed --detail
inspect ls -l /dev/kvm
inspect lsmod
inspect systemctl --no-pager status gdm NetworkManager bluetooth virtqemud.socket virtnetworkd.socket
inspect systemctl --user --no-pager status niri pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk
inspect flatpak list --user --runtime --columns=application,branch
inspect flatpak list --system --runtime --columns=application,branch
inspect id
inspect loginctl session-status --no-pager
printf '\nAUDIT session: XDG_CURRENT_DESKTOP=%s WAYLAND_DISPLAY=%s DISPLAY=%s\n' "${XDG_CURRENT_DESKTOP:-unset}" "${WAYLAND_DISPLAY:-unset}" "${DISPLAY:-unset}"
inspect xdg-mime query default inode/directory
# Candidates only. Never remove GDM dependencies or applications automatically.
if command -v pacman >/dev/null 2>&1; then
    while IFS= read -r package; do
        if [[ $package == linux* ]]; then
            inspect pacman -Qi "$package"
        fi
    done < <(pacman -Qq)
    for package in brightnessctl gnome-software gnome-tweaks gnome-shell-extensions; do
        if pacman -Q "$package" >/dev/null 2>&1; then
            printf '\nAUDIT optional removal candidate (review Required By / Optional For)\n'
            inspect pacman -Qi "$package"
            if command -v pactree >/dev/null 2>&1; then inspect pactree --reverse "$package"; fi
        fi
    done
fi
printf '\nAudit complete; no configuration changes requested. See docs/desktop-recovery.md for acceptance checks.\n'
