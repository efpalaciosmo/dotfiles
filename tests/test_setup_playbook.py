"""Guard the contract between the CachyOS manifest and Ansible setup."""

import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
PLAY = yaml.safe_load((ROOT / "setup.yml").read_text())[0]
MANIFEST = ROOT / "system-packages/cachyos.txt"


def task_named(name, section="tasks"):
    return next(task for task in PLAY[section] if task["name"] == name)


class SetupPlaybookTests(unittest.TestCase):
    def test_manifest_is_valid_and_contains_required_packages(self):
        names = [line for line in MANIFEST.read_text().splitlines() if line and not line.startswith("#")]
        self.assertEqual(len(names), len(set(names)))
        for name in names:
            self.assertRegex(name, r"^[a-z0-9][a-z0-9@._+-]*$")
        for name in (
            "gdm", "gnome-control-center", "gnome-keyring", "nautilus",
            "niri", "xwayland-satellite", "xdg-desktop-portal-gnome",
            "xdg-desktop-portal-gtk", "kitty", "fuzzel", "mako", "waybar",
            "swaylock", "swayidle", "polkit-gnome", "wl-clipboard",
            "pipewire-pulse", "pipewire-alsa", "wireplumber", "flatpak",
            "zathura", "zathura-pdf-mupdf", "zathura-djvu", "qemu-desktop",
            "libvirt", "virt-manager", "dnsmasq", "edk2-ovmf", "swtpm",
            "stow", "swaybg", "zsh", "zsh-completions", "starship", "fontconfig", "make",
            "podman", "distrobox", "epiphany", "bluez", "bluez-utils", "networkmanager", "tailscale",
        ):
            self.assertIn(name, names)
        self.assertNotIn("ansible-core", names)
        self.assertNotIn("python", names)

    def test_package_groups_are_alphabetized(self):
        for group in MANIFEST.read_text().strip().split("\n\n"):
            names = [line for line in group.splitlines() if not line.startswith("#")]
            self.assertEqual(names, sorted(names))

    def test_package_preflight_precedes_privileged_tasks(self):
        preflight = PLAY["pre_tasks"]
        self.assertEqual(preflight[0]["tags"], "always")
        self.assertEqual([task["tags"] for task in preflight[1:]],
                         [["packages", "services", "libvirt"], ["packages", "services", "libvirt"], "packages"])
        self.assertTrue(all(not task.get("become", False) for task in preflight))
        self.assertIn("cachyos", str(preflight[2]["ansible.builtin.assert"]))
        self.assertIn("cachyos_packages", str(preflight[3]["ansible.builtin.assert"]))
        upgrade = task_named("Upgrade the complete CachyOS system")
        install = task_named("Install declared CachyOS packages")
        self.assertLess(PLAY["tasks"].index(upgrade), PLAY["tasks"].index(install))
        for task in (upgrade, install):
            self.assertTrue(task["become"])
            self.assertEqual(task["tags"], "packages")
        self.assertEqual(upgrade["community.general.pacman"], {
            "update_cache": True,
            "upgrade": True,
        })
        self.assertEqual(install["community.general.pacman"], {
            "name": "{{ item }}",
            "state": "present",
        })
        self.assertEqual(install["loop"], "{{ cachyos_packages }}")
        self.assertIn("package_index + 1", install["loop_control"]["label"])
        self.assertTrue(all(
            not task.get("become", False)
            for task in PLAY["tasks"]
            if task not in (upgrade, install, task_named("Remove the system Flathub remote"))
        ))

    def test_services_use_correct_scope_and_leave_gdm_for_next_boot(self):
        tasks = yaml.safe_load((ROOT / "tasks/services.yml").read_text())
        system = next(task for task in tasks if "system services and sockets" in task["name"])
        user = next(task for task in tasks if "user audio services" in task["name"])
        gdm = next(task for task in tasks if task["name"] == "Enable GDM for the next boot")
        self.assertEqual(set(system["loop"]), {"NetworkManager.service", "bluetooth.service", "tailscaled.service"})
        self.assertTrue(system["become"])
        self.assertEqual(set(user["loop"]), {"pipewire.socket", "pipewire-pulse.socket", "wireplumber.service", "podman.socket"})
        self.assertFalse(user.get("become", False))
        for task in (system, user):
            self.assertTrue(task["ansible.builtin.systemd_service"]["enabled"])
            self.assertEqual(task["ansible.builtin.systemd_service"]["state"], "started")
        self.assertEqual(user["ansible.builtin.systemd_service"]["scope"], "user")
        self.assertTrue(gdm["ansible.builtin.systemd_service"]["enabled"])
        self.assertNotIn("state", gdm["ansible.builtin.systemd_service"])
        guard = next(task for task in tasks if task["name"] == "Refuse to replace another display manager")
        self.assertLess(tasks.index(guard), tasks.index(gdm))
        self.assertIn("gdm.service", guard["ansible.builtin.assert"]["that"])

    def test_modular_libvirt_replaces_legacy_sockets_and_checks_connections(self):
        services = yaml.safe_load((ROOT / "tasks/services.yml").read_text())
        included = next(task for task in services if task.get("ansible.builtin.import_tasks") == "libvirt.yml")
        self.assertEqual(included["tags"], "libvirt")
        tasks = yaml.safe_load((ROOT / "tasks/libvirt.yml").read_text())
        legacy = next(task for task in tasks if task["name"] == "Disable and stop legacy libvirt sockets")
        daemon = next(task for task in tasks if task["name"] == "Disable and stop the legacy libvirt daemon")
        modular = next(task for task in tasks if task["name"] == "Enable and start modular libvirt driver sockets")
        self.assertEqual(set(legacy["loop"]), {
            "libvirtd.socket", "libvirtd-ro.socket", "libvirtd-admin.socket",
            "libvirtd-tcp.socket", "libvirtd-tls.socket",
        })
        for task in (legacy, daemon):
            self.assertTrue(task["become"])
            self.assertFalse(task["ansible.builtin.systemd_service"]["enabled"])
            self.assertEqual(task["ansible.builtin.systemd_service"]["state"], "stopped")
            self.assertLess(tasks.index(task), tasks.index(modular))
        self.assertEqual(set(modular["vars"]["libvirt_driver_daemons"]), {
            "virtqemud", "virtnetworkd", "virtstoraged", "virtnodedevd",
            "virtnwfilterd", "virtsecretd", "virtinterfaced", "virtproxyd",
        })
        self.assertIn("['', '-ro', '-admin']", modular["loop"])
        self.assertTrue(modular["become"])
        self.assertTrue(modular["ansible.builtin.systemd_service"]["enabled"])
        self.assertEqual(modular["ansible.builtin.systemd_service"]["state"], "started")
        verify = next(task for task in tasks if task["name"] == "Verify system libvirt connections")
        self.assertEqual(verify["loop"], ["list", "net-list", "pool-list"])
        self.assertIn("--readonly", verify["ansible.builtin.command"]["argv"])
        self.assertIn("qemu:///system", verify["ansible.builtin.command"]["argv"])
        self.assertFalse(verify["changed_when"])
        self.assertFalse(verify.get("become", False))

    def test_pacman_never_combines_name_and_upgrade(self):
        for task in PLAY["tasks"]:
            pacman = task.get("community.general.pacman")
            if pacman:
                self.assertFalse("name" in pacman and "upgrade" in pacman)

    def test_static_checks_run_before_any_mutating_task(self):
        self.assertEqual(PLAY["tasks"][0]["name"], "Run static repository checks")
        self.assertFalse(PLAY["tasks"][0].get("become", False))

    def test_local_tasks_use_existing_helpers_and_skip_check_mode(self):
        fonts = task_named("Install user-local fonts")
        links = task_named("Link dotfiles with safe conflict backups")
        self.assertIn("scripts/install-fonts.sh", fonts["ansible.builtin.command"]["argv"][0])
        self.assertIn("scripts/apply-dotfiles.sh", links["ansible.builtin.command"]["argv"])
        for task in PLAY["tasks"]:
            conditions = task["when"]
            if isinstance(conditions, str):
                conditions = [conditions]
            self.assertIn("not ansible_check_mode", conditions)
        for task in (fonts, links, task_named("Run static repository checks")):
            self.assertIn("local", task["tags"])


if __name__ == "__main__":
    unittest.main()
