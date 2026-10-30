#!/usr/bin/env python3
"""Read-only desktop checks; exit bits 1=missing and 2=pending."""
import os
import grp
import re
import subprocess
from pathlib import Path


def run(*args, timeout=20):
    result = subprocess.run(args, text=True, capture_output=True, timeout=timeout,
                            env={**os.environ, 'LC_ALL': 'C'})
    if result.returncode:
        raise RuntimeError(f"{' '.join(args)}: {result.stderr.strip() or result.stdout.strip()}")
    return result.stdout.strip()


class Checks:
    def __init__(self):
        self.missing = 0
        self.pending = 0

    def report(self, state, message):
        print(f'{state:7} {message}')
        self.missing += state == 'MISS'
        self.pending += state == 'PENDING'

    def command(self, message, *args):
        try:
            output = run(*args, timeout=20)
        except (OSError, RuntimeError, subprocess.SubprocessError) as error:
            self.report('MISS', f'{message}: {error}')
            return None
        self.report('OK', message)
        return output

    def hardware(self):
        if not list(Path('/sys/class/power_supply').glob('BAT*')):
            self.report('INFO', 'optional battery absent (desktop)')
        if not list(Path('/sys/class/backlight').glob('*')):
            self.report('INFO', 'optional laptop backlight absent (desktop)')

    def session(self):
        if 'niri' not in os.environ.get('XDG_CURRENT_DESKTOP', '').lower() or not os.environ.get('WAYLAND_DISPLAY'):
            self.report('PENDING', 'log in through GDM → Niri to check keyring, portals, audio, notifications and Xwayland')
            return
        association = self.command('directory association', 'xdg-mime', 'query', 'default', 'inode/directory')
        if association is not None and association != 'org.gnome.Nautilus.desktop':
            self.report('MISS', 'set Nautilus with: xdg-mime default org.gnome.Nautilus.desktop inode/directory')
        for interface in ('FileChooser', 'ScreenCast', 'Secret'):
            self.command(f'portal {interface} activation', 'busctl', '--user', 'introspect',
                         'org.freedesktop.portal.Desktop', '/org/freedesktop/portal/desktop',
                         'org.freedesktop.portal.' + interface)
        self.command('notification service', 'busctl', '--user', 'introspect',
                     'org.freedesktop.Notifications', '/org/freedesktop/Notifications', 'org.freedesktop.Notifications')
        unlocked = self.command('keyring default collection', 'busctl', '--user', 'get-property',
                                'org.freedesktop.secrets', '/org/freedesktop/secrets/aliases/default',
                                'org.freedesktop.Secret.Collection', 'Locked')
        if unlocked is not None and unlocked != 'b false':
            self.report('MISS', 'default keyring is locked; verify GDM password login and matching keyring password')
        self.command('PipeWire/WirePlumber graph', 'wpctl', 'status')
        self.command('Xwayland satellite binary', 'xwayland-satellite', '--version')
        for unit in ('dotfiles-clipboard-text.service', 'dotfiles-clipboard-image.service'):
            self.command(f'clipboard watcher {unit}', 'systemctl', '--user', 'is-active', unit)
        self.report('INFO', 'test Ctrl+C/Ctrl+V in apps, Ctrl+Shift+C/V in Ghostty, text/PNG history and Wayland ↔ X11 transfers')
        self.report('OK' if os.environ.get('DISPLAY') else 'MISS', 'Xwayland DISPLAY exported by Niri')
        self.report('INFO', 'manually test file picking, screen sharing, playback, notifications and an X11 application')
        self.report('INFO', 'manually test lock, suspend/resume, phone/USB/SMB access')

    def virtualization(self):
        if not Path('/etc/systemd/system/cachyos-libvirt-network.service').is_file():
            return
        try:
            group = grp.getgrnam('libvirt')
        except KeyError:
            self.report('MISS', 'libvirt group is missing; run make setup')
            return
        if group.gr_gid not in os.getgroups() and group.gr_gid != os.getgid():
            self.report('PENDING', 'log out completely and sign in again to load libvirt group membership')
            return
        self.report('OK', 'current session has libvirt group membership')
        if not os.environ.get('WAYLAND_DISPLAY') and not os.environ.get('DISPLAY'):
            self.report('PENDING', 'check passwordless libvirt from an active local graphical login')
            return
        # No --allow-user-interaction: diagnosis must never open a password prompt.
        authorized = self.command('passwordless local libvirt authorization', 'pkcheck',
                                  '--action-id', 'org.libvirt.unix.manage', '--process', str(os.getpid()))
        if authorized is None:
            return
        self.command('system VM connection (read/write authorization, read-only query)',
                     'virsh', '--connect', 'qemu:///system', 'list', '--all')
        self.command('next-boot NAT setup', 'systemctl', 'is-active', 'cachyos-libvirt-network.service')
        network = self.command('default VM NAT', 'virsh', '--connect', 'qemu:///system', 'net-info', 'default')
        if network is not None:
            for field in ('Active', 'Autostart'):
                if not re.search(rf'^{field}:\s+yes\s*$', network, re.M):
                    self.report('MISS', f'default VM NAT {field.lower()} is not yes; inspect the network service journal')
        self.report('INFO', 'boot a real KVM guest; test DHCP/DNS/HTTPS, UEFI/TPM, 3D and SPICE clipboard with guest agents')


def main():
    checks = Checks()
    checks.hardware()
    checks.session()
    checks.virtualization()
    return (1 if checks.missing else 0) | (2 if checks.pending else 0)


if __name__ == '__main__':
    raise SystemExit(main())
