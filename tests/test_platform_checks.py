"""Regressions found using actual rolling-release packages, not just stubs."""

import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("platform_installer", ROOT / "scripts/cachyos.py")
installer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(installer)
PAM = "-auth optional pam_gnome_keyring.so\n-session optional pam_gnome_keyring.so auto_start\n"


class PlatformChecks(unittest.TestCase):
    def test_runtime_check_requires_active_services_not_only_enablement(self):
        plan = {"system_units": ["firewalld.service", "gdm.service", "virtqemud.socket"]}
        with patch.object(installer, "run", return_value="active"):
            self.assertEqual(installer.runtime_system_problems(plan), [])
        with patch.object(installer, "run", return_value="failed"):
            problems = installer.runtime_system_problems(plan)
            self.assertEqual(len(problems), 3)
            self.assertTrue(any("firewalld" in item for item in problems))

    def test_user_portals_do_not_lose_the_system_fallback_routes(self):
        user = ROOT / "packages/niri/.config/xdg-desktop-portal/niri-portals.conf"
        system = ROOT / "cachyos/config/niri-portals.conf"
        self.assertEqual(user.read_text(), system.read_text())

    def test_clipboard_watchers_are_supervised_and_session_scoped(self):
        startup = (ROOT / "packages/niri/.config/niri/autostart.kdl").read_text()
        self.assertNotIn('spawn-sh-at-startup "wl-paste', startup)
        for kind in ("text", "image"):
            name = f"dotfiles-clipboard-{kind}.service"
            self.assertIn(name, startup)
            service = (ROOT / "packages/fuzzel/.config/systemd/user" / name).read_text()
            self.assertIn("PartOf=graphical-session.target", service)
            self.assertIn("After=graphical-session.target", service)
            self.assertIn("Restart=on-failure", service)

    def test_stateless_pam_is_supported_but_etc_overrides_take_precedence(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            vendor = root / "usr/lib/pam.d/gdm-password"
            vendor.parent.mkdir(parents=True)
            vendor.write_text(PAM)
            self.assertTrue(installer.gdm_keyring_configured(root))
            override = root / "etc/pam.d/gdm-password"
            override.parent.mkdir(parents=True)
            override.write_text("# " + PAM.replace("\n", "\n# "))
            self.assertFalse(installer.gdm_keyring_configured(root))
            override.write_text(PAM)
            self.assertTrue(installer.gdm_keyring_configured(root))

    def test_keyring_needs_both_password_capture_and_session_start(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            pam = root / "etc/pam.d/gdm-password"
            pam.parent.mkdir(parents=True)
            for text in ("", "auth optional pam_gnome_keyring.so\n", "session optional pam_gnome_keyring.so\n"):
                pam.write_text(text)
                self.assertFalse(installer.gdm_keyring_configured(root))

    def test_virtio_gl_selection_includes_base_and_vga_modules(self):
        packages = set(installer.MANIFEST["modules"]["virtualization-3d"]["packages"])
        required = {"qemu-hw-display-" + name for name in (
            "virtio-gpu", "virtio-gpu-pci", "virtio-gpu-gl", "virtio-gpu-pci-gl", "virtio-vga", "virtio-vga-gl")}
        self.assertLessEqual(required, packages)
        self.assertLessEqual({"qemu-audio-spice", "qemu-audio-pipewire"}, packages)

    def test_nat_requests_real_current_package_not_only_its_virtual_provide(self):
        packages = installer.MANIFEST["modules"]["virtualization-core"]["packages"]
        self.assertIn("iptables", packages)
        self.assertNotIn("iptables-nft", packages)

    def test_missing_kvm_fails_instead_of_assuming_a_binary_proves_acceleration(self):
        with patch.object(installer.os, "open", side_effect=FileNotFoundError), self.assertRaisesRegex(installer.Refusal, "SVM"):
            installer.check_kvm()

    def test_kvm_api_probe_closes_device_without_creating_a_vm(self):
        with patch.object(installer.os, "open", return_value=7), \
                patch.object(installer.os, "close") as close, \
                patch.object(installer.fcntl, "ioctl", return_value=12) as ioctl:
            installer.check_kvm()
        ioctl.assert_called_once_with(7, 0xAE00)
        close.assert_called_once_with(7)
