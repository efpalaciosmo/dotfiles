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

    def test_app_installation_stays_opt_in_and_user_scoped(self):
        shared = yaml.safe_load((ROOT / "tasks/flathub-user.yml").read_text())
        tasks = PLAY["tasks"] + shared
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
        setup = yaml.safe_load((ROOT / "setup.yml").read_text())[0]["tasks"]
        self.assertFalse(any("flathub_apps" in str(task) or "flatpak.yml" in str(task) for task in setup))
        makefile = (ROOT / "Makefile").read_text()
        self.assertIn("flatpak: ##", makefile)
        self.assertNotIn("setup: flatpak", makefile)

    def test_setup_replaces_system_remote_after_packages_without_removing_apps(self):
        tasks = yaml.safe_load((ROOT / "setup.yml").read_text())[0]["tasks"]
        install = next(task for task in tasks if task["name"] == "Install declared CachyOS packages")
        remote = next(task for task in tasks if task["name"] == "Configure the user Flathub remote")
        remove = next(task for task in tasks if task["name"] == "Remove the system Flathub remote")
        self.assertLess(tasks.index(install), tasks.index(remote))
        self.assertLess(tasks.index(remote), tasks.index(remove))
        self.assertTrue(remove["become"])
        self.assertEqual(remove["tags"], "packages")
        argv = remove["ansible.builtin.command"]["argv"]
        self.assertEqual(argv, ["flatpak", "remote-delete", "--system", "flathub"])
        self.assertNotIn("--force", argv)
        self.assertIn("'flathub' in system_remotes.stdout_lines", remove["when"])


if __name__ == "__main__":
    unittest.main()
