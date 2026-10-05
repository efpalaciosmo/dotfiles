"""The CachyOS installer must be safe to test without pacman or sudo."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "scripts/install-system-packages.sh"
MANIFEST = ROOT / "system-packages/cachyos.txt"


class SystemPackageTests(unittest.TestCase):
    def test_requested_packages_and_stow_are_declared(self):
        names = [line for line in MANIFEST.read_text().splitlines() if line and not line.startswith("#")]
        self.assertEqual(len(names), len(set(names)))
        for name in (
            "gdm", "gnome-control-center", "gnome-keyring", "nautilus", "niri",
            "xwayland-satellite", "xdg-desktop-portal-gnome", "xdg-desktop-portal-gtk",
            "kitty", "fuzzel", "mako", "waybar", "swaylock", "swayidle",
            "polkit-gnome", "wl-clipboard", "pipewire-pulse", "pipewire-alsa",
            "wireplumber", "flatpak", "zathura", "zathura-pdf-mupdf",
            "zathura-djvu", "qemu-desktop", "libvirt", "virt-manager", "dnsmasq",
            "edk2-ovmf", "swtpm", "stow", "swaybg", "python", "fontconfig",
        ):
            self.assertIn(name, names)

    def test_rejects_other_distributions_before_running_sudo(self):
        with tempfile.TemporaryDirectory() as directory:
            fake_sudo = Path(directory) / "sudo"
            fake_sudo.write_text('#!/bin/sh\nprintf called > "$MARKER"\n')
            fake_sudo.chmod(0o755)
            marker = Path(directory) / "called"
            env = {**os.environ, "PATH": directory + ":" + os.environ["PATH"], "MARKER": str(marker)}
            command = 'source "$1"; is_cachyos() { return 1; }; main'
            result = subprocess.run(["bash", "-c", command, "bash", str(INSTALLER)], env=env, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(marker.exists())

    def test_pacman_receives_full_upgrade_and_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            for name in ("sudo", "pacman"):
                stub = Path(directory) / name
                stub.write_text('#!/bin/sh\nprintf "%s\\0" "$@"\n')
                stub.chmod(0o755)
            env = {**os.environ, "PATH": directory + ":" + os.environ["PATH"]}
            command = 'source "$1"; is_cachyos() { return 0; }; main'
            result = subprocess.run(["bash", "-c", command, "bash", str(INSTALLER)], env=env, capture_output=True, check=True)
            args = result.stdout.split(b"\0")[:-1]
            self.assertEqual(args[:3], [b"pacman", b"-Syu", b"--needed"])
            self.assertIn(b"stow", args)
            self.assertIn(b"swayidle", args)
            self.assertEqual(len(args) - 3, len([line for line in MANIFEST.read_text().splitlines() if line and not line.startswith("#")]))

    def test_invalid_manifest_entry_never_reaches_sudo(self):
        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory) / "bad.txt"
            manifest.write_text("stow\nbad;command\n")
            stub = Path(directory) / "sudo"
            stub.write_text('#!/bin/sh\nprintf called > "$MARKER"\n')
            stub.chmod(0o755)
            pacman = Path(directory) / "pacman"
            pacman.write_text("#!/bin/sh\nexit 0\n")
            pacman.chmod(0o755)
            marker = Path(directory) / "called"
            env = {**os.environ, "PATH": directory + ":" + os.environ["PATH"], "MARKER": str(marker)}
            command = 'source "$1"; is_cachyos() { return 0; }; manifest=$2; main'
            result = subprocess.run(["bash", "-c", command, "bash", str(INSTALLER), str(manifest)], env=env, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(b"invalid package name", result.stderr)
            self.assertFalse(marker.exists())


if __name__ == "__main__":
    unittest.main()
