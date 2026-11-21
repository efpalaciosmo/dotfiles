"""Utility sizing must not float unrelated apps or browser/document titles."""

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RULES = (ROOT / "packages/niri/.config/niri/rules.kdl").read_text()


def matching_rules(app_id, title=""):
    for block in RULES.split("window-rule {")[1:]:
        matches = re.findall(r'^\s*match app-id=r#"(.*?)"#(?: title="(.*?)")?$', block, re.M)
        if any(re.search(app, app_id) and (not name or re.search(name, title))
               for app, name in matches):
            yield block


class WindowRuleTests(unittest.TestCase):
    def test_installed_utilities_float_at_the_chosen_logical_size(self):
        cases = {
            ("thunar", "Files"): (1000, 720),
            ("io.github.peazip.PeaZip", ""): (1000, 720),
            ("xarchiver", ""): (1000, 720),
            ("org.gnome.Calculator", ""): (440, 600),
            ("io.github.maniacx.BudsLink", ""): (480, 640),
            ("com.rafaelmardojai.Blanket", ""): (560, 660),
            ("org.pulseaudio.pavucontrol", ""): (760, 560),
            ("pavucontrol", ""): (760, 560),
            ("blueman-manager", ""): (760, 560),
            ("nm-connection-editor", ""): (760, 560),
            ("org.localsend.localsend_app", ""): (760, 600),
            ("io.gitlab.adhami3310.Impression", ""): (640, 520),
            ("com.vysp3r.ProtonPlus", ""): (760, 640),
            ("io.github.cosmic_utils.camera", ""): (960, 720),
            ("io.github.diegopvlk.Cine", ""): (960, 720),
            ("gpu-screen-recorder-gtk", ""): (900, 700),
            ("FurMark_GUI", ""): (900, 700),
            ("com.github.tchx84.Flatseal", ""): (1000, 760),
            ("org.gnome.Settings", ""): (1000, 760),
            ("io.github.flattool.Warehouse", ""): (1100, 760),
            ("io.missioncenter.MissionCenter", ""): (1100, 760),
        }
        for (app, title), (width, height) in cases.items():
            with self.subTest(app=app):
                rules = "\n".join(matching_rules(app, title))
                self.assertIn("open-floating true", rules)
                self.assertIn(f"default-column-width {{ fixed {width}; }}", rules)
                self.assertIn(f"default-window-height {{ fixed {height}; }}", rules)
                self.assertNotIn("max-width", rules)
                self.assertNotIn("max-height", rules)

    def test_bitwarden_popout_floats_compact_and_is_hidden_from_screencasts(self):
        for app in ("app.zen_browser.zen", "com.brave.Browser", "firefox"):
            for title in ("Bitwarden", "Bitwarden — Zen Browser", "Bitwarden - Brave"):
                with self.subTest(app=app, title=title):
                    rules = "\n".join(matching_rules(app, title))
                    self.assertIn("open-floating true", rules)
                    self.assertIn("default-column-width { fixed 420; }", rules)
                    self.assertIn("default-window-height { fixed 680; }", rules)
                    self.assertIn('block-out-from "screencast"', rules)

    def test_bitwarden_rule_does_not_catch_the_web_vault_or_other_tabs(self):
        for title in ("Bitwarden Web Vault", "My Vault | Bitwarden", "Zen Browser", ""):
            with self.subTest(title=title):
                self.assertEqual(list(matching_rules("app.zen_browser.zen", title)), [])

    def test_workspace_apps_and_unrelated_titles_keep_default_tiling(self):
        for app in ("app.zen_browser.zen", "com.brave.Browser", "com.mitchellh.ghostty",
                    "com.bambulab.BambuStudio", "com.orcaslicer.OrcaSlicer",
                    "com.obsproject.Studio", "org.kde.kdenlive", "org.inkscape.Inkscape",
                    "org.libreoffice.LibreOffice", "org.gnome.Papers", "org.gnome.TextEditor",
                    "org.gnome.Boxes", "com.github.marhkb.Pods", "io.github.kolunmi.Bazaar",
                    "com.usebruno.Bruno", "md.obsidian.Obsidian", "com.valvesoftware.Steam",
                    "net.pcsx2.PCSX2", "org.qbittorrent.qBittorrent", "com.rtosta.zapzap",
                    "org.telegram.desktop", "dev.vencord.Vesktop"):
            with self.subTest(app=app):
                self.assertEqual(list(matching_rules(app, "Calculator — Volume Control")), [])

    def test_steam_games_only_get_adaptive_sync_and_still_tile(self):
        rules = "\n".join(matching_rules("steam_app_1234", "Calculator — Volume Control"))
        self.assertIn("variable-refresh-rate true", rules)
        for forbidden in ("open-floating", "default-column-width", "default-window-height"):
            self.assertNotIn(forbidden, rules)

    def test_only_the_thunar_app_id_floats_not_every_ghostty_window(self):
        for app in ("com.mitchellh.ghostty", "thunar.other", "thunar-settings"):
            with self.subTest(app=app):
                self.assertEqual(list(matching_rules(app, "Files")), [])

    def test_pip_remains_small_quiet_and_bottom_right(self):
        for app in ("app.zen_browser.zen", "firefox", "org.mozilla.firefox"):
            rules = "\n".join(matching_rules(app, "Picture-in-Picture"))
            self.assertIn("open-floating true", rules)
            self.assertIn("open-focused false", rules)
            self.assertIn("fixed 480", rules)
            self.assertIn("fixed 270", rules)
            self.assertIn('relative-to="bottom-right"', rules)
