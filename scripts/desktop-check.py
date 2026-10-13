#!/usr/bin/env python3
"""Read-only desktop checks; exit bits 1=missing and 2=pending."""
import os
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
        for path in ('/sys/module/kvm_amd', '/dev/kvm'):
            self.report('OK' if Path(path).exists() else 'MISS', path)
        for package in ('amd-ucode', 'linux-firmware', 'chwd', 'pciutils', 'gvfs-mtp', 'gvfs-afc', 'gvfs-smb'):
            self.command(f'package {package}', 'pacman', '-Q', package)
        info = self.command('default NAT network', 'virsh', '--readonly', '--connect', 'qemu:///system', 'net-info', 'default')
        if info is not None:
            import re
            if not all(re.search(rf'^{field}:\s+yes$', info, re.M) for field in ('Active', 'Autostart')):
                self.report('MISS', 'default NAT must be active and autostarted; run make libvirt')
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
        self.report('OK' if os.environ.get('DISPLAY') else 'MISS', 'Xwayland DISPLAY exported by Niri')
        self.report('INFO', 'manually test file picking, screen sharing, playback, notifications and an X11 application')
        self.report('INFO', 'manually test lock, suspend/resume, phone/USB/SMB access, and a VM with NAT connectivity')


def main():
    checks = Checks()
    checks.hardware()
    checks.session()
    return (1 if checks.missing else 0) | (2 if checks.pending else 0)


if __name__ == '__main__':
    raise SystemExit(main())
