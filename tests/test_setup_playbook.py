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
        ):
            self.assertIn(name, names)
        self.assertNotIn("ansible-core", names)
        self.assertNotIn("python", names)

    def test_package_preflight_precedes_only_privileged_task(self):
        preflight = PLAY["pre_tasks"]
        self.assertEqual(preflight[0]["tags"], "always")
        self.assertEqual([task["tags"] for task in preflight[1:]], ["packages"] * 3)
        self.assertTrue(all(not task.get("become", False) for task in preflight))
        self.assertIn("cachyos", str(preflight[2]["ansible.builtin.assert"]))
        self.assertIn("cachyos_packages", str(preflight[3]["ansible.builtin.assert"]))
        packages = task_named("Upgrade CachyOS and install declared packages")
        self.assertTrue(packages["become"])
        self.assertEqual(packages["tags"], "packages")
        pacman = packages["community.general.pacman"]
        self.assertEqual(pacman["name"], "{{ cachyos_packages }}")
        self.assertEqual(pacman["state"], "present")
        self.assertTrue(pacman["update_cache"])
        self.assertTrue(pacman["upgrade"])
        self.assertTrue(all(not task.get("become", False) for task in PLAY["tasks"] if task is not packages))

    def test_static_checks_run_before_any_mutating_task(self):
        self.assertEqual(PLAY["tasks"][0]["name"], "Run static repository checks")
        self.assertFalse(PLAY["tasks"][0].get("become", False))

    def test_local_tasks_use_existing_helpers_and_skip_check_mode(self):
        fonts = task_named("Install user-local fonts")
        links = task_named("Link dotfiles with safe conflict backups")
        self.assertIn("scripts/install-fonts.sh", fonts["ansible.builtin.command"]["argv"][0])
        self.assertIn("scripts/apply-dotfiles.sh", links["ansible.builtin.command"]["argv"])
        for task in PLAY["tasks"]:
            self.assertEqual(task["when"], "not ansible_check_mode")
        for task in (fonts, links, task_named("Run static repository checks")):
            self.assertIn("local", task["tags"])


if __name__ == "__main__":
    unittest.main()
