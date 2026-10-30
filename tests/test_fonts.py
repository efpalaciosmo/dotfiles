"""HiDPI app typography and read-only detection of fontconfig substitution."""

import configparser
import os
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class FontTests(unittest.TestCase):
    def check_font(self, matched):
        with tempfile.TemporaryDirectory() as directory:
            command = Path(directory) / "fc-match"
            command.write_text('#!/bin/sh\nprintf "%s\\n" "$MATCHED_FONT"\n')
            command.chmod(0o755)
            return subprocess.run(["bash", str(ROOT / "scripts/check-fonts.sh")],
                                  env={**os.environ, "PATH": f"{directory}:{os.environ['PATH']}",
                                       "MATCHED_FONT": matched}, capture_output=True, text=True)

    def test_font_substitution_is_not_reported_as_jetbrains(self):
        result = self.check_font("DejaVu Sans Mono")
        self.assertEqual(result.returncode, 1)
        self.assertIn("substitutes DejaVu Sans Mono", result.stderr)

    def test_jetbrains_family_and_aliases_are_accepted(self):
        for family in ("JetBrainsMono Nerd Font", "JetBrainsMono Nerd Font,JetBrainsMono NF"):
            result = self.check_font(family)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_larger_fuzzel_uses_jetbrains_and_output_scaling(self):
        config = configparser.ConfigParser()
        config.read(ROOT / "packages/fuzzel/.config/fuzzel/fuzzel.ini")
        main = config["main"]
        self.assertEqual(main["font"], "JetBrainsMono Nerd Font:size=13,JetBrains Mono:size=13")
        self.assertEqual(main["dpi-aware"], "no")
        self.assertEqual(main["width"], "52")
        self.assertEqual(main["lines"], "10")
        self.assertEqual(main["line-height"], "36px")
        self.assertEqual(config["colors"]["background"], "36363aff")

    def test_desktop_and_other_managed_apps_default_to_jetbrains(self):
        for version in ("3.0", "4.0"):
            config = configparser.ConfigParser()
            config.read(ROOT / f"packages/desktop/.config/gtk-{version}/settings.ini")
            self.assertEqual(config["Settings"]["gtk-font-name"], "JetBrainsMono Nerd Font 12")
        for file, setting in (
            ("packages/mako/.config/mako/config", "font=JetBrainsMono Nerd Font 12"),
            ("packages/desktop/.config/swaylock/config", "font=JetBrainsMono Nerd Font"),
            ("packages/desktop/.config/zathura/zathurarc", 'set font "JetBrainsMono Nerd Font 12"'),
        ):
            self.assertIn(setting, (ROOT / file).read_text(), file)

    def test_fontconfig_defaults_cover_generic_families_without_forced_replacement(self):
        root = ET.parse(ROOT / "packages/desktop/.config/fontconfig/fonts.conf").getroot()
        self.assertEqual(root.tag, "fontconfig")
        aliases = {alias.findtext("family"): [family.text for family in alias.findall("prefer/family")]
                   for alias in root.findall("alias")}
        self.assertEqual(set(aliases), {"sans-serif", "serif", "monospace", "system-ui"})
        for preferred in aliases.values():
            self.assertEqual(preferred, ["JetBrainsMono Nerd Font", "JetBrains Mono"])
        self.assertIsNone(root.find("match"))

    def test_no_managed_text_config_explicitly_selects_adwaita_fonts(self):
        for file in (ROOT / "packages").rglob("*"):
            if not file.is_file() or "backgrounds" in file.parts or "__pycache__" in file.parts:
                continue
            text = file.read_text()
            self.assertNotIn("Adwaita Sans", text, str(file.relative_to(ROOT)))
            self.assertNotIn("Adwaita Mono", text, str(file.relative_to(ROOT)))
