"""Persist Adwaita preferences from either a desktop session or first-install TTY."""

import configparser
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class AppearanceTests(unittest.TestCase):
    def run_helper(self, bus=True, persist=True, installed="", flatpak_failure=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            gsettings = root / "gsettings"
            gsettings.write_text('''#!/bin/sh
case "$1" in
    list-keys) printf 'color-scheme\ngtk-theme\nicon-theme\ncursor-theme\ncursor-size\nfont-name\ndocument-font-name\nmonospace-font-name\ntitlebar-font\ntitlebar-uses-system-font\naccent-color\n' ;;
    writable) echo true ;;
    get) if [ -f "$STATE/$3" ]; then cat "$STATE/$3"; else echo unset; fi ;;
    set) printf '%s=%s\n' "$3" "$4" >> "$LOG"; if [ "$PERSIST" = yes ]; then printf '%s' "$4" > "$STATE/$3"; fi ;;
esac
''')
            gsettings.chmod(0o755)
            dbus = root / "dbus-run-session"
            dbus.write_text('''#!/bin/sh
echo bus >> "$LOG"
shift
export DBUS_SESSION_BUS_ADDRESS=test-bus
exec "$@"
''')
            dbus.chmod(0o755)
            flatpak = root / "flatpak"
            flatpak.write_text('''#!/bin/sh
case "$1" in
    list) printf '%s\n' "$INSTALLED" ;;
    override) printf 'flatpak %s\n' "$*" >> "$LOG"; [ "$FLATPAK_FAILURE" = no ] ;;
esac
''')
            flatpak.chmod(0o755)
            env = {**os.environ, "PATH": f"{root}:{os.environ['PATH']}", "STATE": directory,
                   "LOG": str(root / "calls"), "PERSIST": "yes" if persist else "no",
                   "INSTALLED": installed, "FLATPAK_FAILURE": "yes" if flatpak_failure else "no"}
            if bus:
                env["DBUS_SESSION_BUS_ADDRESS"] = "test-bus"
            else:
                env.pop("DBUS_SESSION_BUS_ADDRESS", None)
            result = subprocess.run([str(ROOT / "packages/desktop/.local/bin/dotfiles-appearance")],
                                    env=env, text=True, capture_output=True)
            return result, (root / "calls").read_text().splitlines()

    def test_tty_gets_a_session_bus_and_persists_adwaita(self):
        result, calls = self.run_helper(bus=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[0], "bus")
        self.assertIn("color-scheme='prefer-dark'", calls)
        self.assertIn("accent-color='orange'", calls)
        self.assertIn("monospace-font-name='JetBrainsMono Nerd Font 12'", calls)
        self.assertIn("document-font-name='JetBrainsMono Nerd Font 12'", calls)
        self.assertIn("titlebar-font='JetBrainsMono Nerd Font Bold 12'", calls)
        self.assertIn("titlebar-uses-system-font=true", calls)

    def test_existing_session_bus_is_reused(self):
        result, calls = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("bus", calls)

    def test_silent_settings_write_failure_cannot_report_success(self):
        result, calls = self.run_helper(persist=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("failed to persist", result.stderr)

    def test_shared_adwaita_preferences_and_app_palettes_are_consistent(self):
        result, calls = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        for value in ("gtk-theme='Adwaita'", "icon-theme='Adwaita'",
                      "cursor-theme='Adwaita'", "font-name='JetBrainsMono Nerd Font 12'"):
            self.assertIn(value, calls)
        gtk = configparser.ConfigParser()
        gtk.read(ROOT / "packages/desktop/.config/gtk-3.0/settings.ini")
        self.assertEqual(gtk["Settings"]["gtk-theme-name"], "Adwaita")
        self.assertTrue(gtk["Settings"].getboolean("gtk-application-prefer-dark-theme"))
        self.assertEqual(gtk["Settings"]["gtk-font-name"], "JetBrainsMono Nerd Font 12")
        for file in ("packages/niri/.config/niri/layout.kdl",
                     "packages/waybar/.config/waybar/style.css",
                     "packages/ghostty/.config/ghostty/themes/Adwaita Dark Orange",
                     "packages/desktop/.config/zathura/zathurarc",
                     "packages/mako/.config/mako/config"):
            self.assertIn("#ff7800", (ROOT / file).read_text(), file)
        fuzzel = (ROOT / "packages/fuzzel/.config/fuzzel/fuzzel.ini").read_text()
        self.assertIn("selection=ff7800ff", fuzzel)
        self.assertIn("dpi-aware=no", fuzzel)

    def test_only_installed_gtk3_flatpaks_get_a_scoped_dark_variant(self):
        apps = ("app.zen_browser.zen", "com.brave.Browser", "com.bambulab.BambuStudio",
                "com.orcaslicer.OrcaSlicer", "com.dec05eba.gpu_screen_recorder",
                "org.inkscape.Inkscape", "org.libreoffice.LibreOffice")
        result, calls = self.run_helper(installed="\n".join((*apps, apps[0],
            "org.gnome.Calculator", "com.github.tchx84.Flatseal", "org.kde.kdenlive")))
        self.assertEqual(result.returncode, 0, result.stderr)
        overrides = [line for line in calls if line.startswith("flatpak ")]
        self.assertCountEqual(overrides, [
            f"flatpak override --user --env=GTK_THEME=Adwaita:dark {app}" for app in apps])
        self.assertFalse(any("--filesystem" in line or "--reset" in line for line in overrides))

    def test_flatpak_failure_cannot_report_success(self):
        result, _ = self.run_helper(installed="org.inkscape.Inkscape", flatpak_failure=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("applied", result.stdout)
