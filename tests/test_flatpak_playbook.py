"""Flatpak installations must be opt-in and user-scoped."""

import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
PLAY = yaml.safe_load((ROOT / "flatpak.yml").read_text())[0]
MANIFEST = ROOT / "flatpak-apps/flathub.txt"


class FlatpakPlaybookTests(unittest.TestCase):
    def test_requested_apps_and_extensions_are_declared(self):
        apps = [line for line in MANIFEST.read_text().splitlines() if line and not line.startswith("#")]
        self.assertEqual(len(apps), len(set(apps)))
        self.assertEqual(len(apps), 42)
        self.assertIn("com.valvesoftware.Steam", apps)
        self.assertIn("com.valvesoftware.SteamLink", apps)
        self.assertIn("com.brave.Browser", apps)
        self.assertLess(apps.index("com.obsproject.Studio"), apps.index("com.obsproject.Studio.Plugin.OBSVkCapture"))
        self.assertLess(apps.index("org.openrgb.OpenRGB"), apps.index("org.openrgb.OpenRGB.Plugin.Effects"))

    def test_no_system_flatpak_or_automatic_setup(self):
        tasks = PLAY["tasks"]
        self.assertFalse(any(task.get("become", False) for task in tasks))
        remote = next(task for task in tasks if task["name"].startswith("Add Flathub"))
        remotes = next(task for task in tasks if task["name"].startswith("Read only user Flatpak remotes"))
        install = next(task for task in tasks if task["name"].startswith("Install apps"))
        self.assertEqual(remotes["ansible.builtin.command"]["argv"],
                         ["flatpak", "remotes", "--user", "--columns=name,url"])
        self.assertIn("--user", remote["ansible.builtin.command"]["argv"])
        self.assertIn("--if-not-exists", remote["ansible.builtin.command"]["argv"])
        self.assertIn("--user", install["ansible.builtin.command"]["argv"])
        self.assertIn("--noninteractive", install["ansible.builtin.command"]["argv"])
        self.assertFalse(any("flatpak" in str(task).lower() for task in yaml.safe_load((ROOT / "setup.yml").read_text())[0]["tasks"]))
        makefile = (ROOT / "Makefile").read_text()
        self.assertIn("flatpak: ##", makefile)
        self.assertNotIn("setup: flatpak", makefile)


if __name__ == "__main__":
    unittest.main()
