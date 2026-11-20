"""Complementary column widths must fit the configured 150% 4K output."""

import math
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LAYOUT = (ROOT / "packages/niri/.config/niri/layout.kdl").read_text()
KEYBOARD = (ROOT / "packages/niri/.config/niri/keyboard.kdl").read_text()


def tile_width(width, proportion, gaps, border, scale):
    # Niri floors the requested Wayland window size to logical pixels, then
    # rounds the returned size to physical pixels and adds the rounded border.
    rounded_border = math.floor(border * scale + 0.5) / scale
    requested = math.floor((width - gaps) * proportion - gaps - 2 * rounded_border)
    return math.floor(requested * scale + 0.5) / scale + 2 * rounded_border


class NiriLayoutTests(unittest.TestCase):
    def test_complementary_width_presets_fit_4k_at_150_percent(self):
        gaps = float(re.search(r"^\s*gaps ([\d.]+)$", LAYOUT, re.M)[1])
        border = float(re.search(r"border \{\s*on\s*width ([\d.]+)", LAYOUT)[1])
        presets = re.search(r"preset-column-widths \{(.*?)\}", LAYOUT, re.S)[1]
        proportions = [float(value) for value in re.findall(r"proportion ([\d.]+)", presets)]
        for first, second in ((0.25, 0.75), (0.3, 0.7), (0.4, 0.6), (0.5, 0.5)):
            with self.subTest(pair=(first, second)):
                self.assertIn(first, proportions)
                self.assertIn(second, proportions)
                total = sum(tile_width(2560, p, gaps, border, 1.5) for p in (first, second))
                self.assertLessEqual(total + 3 * gaps, 2560)

    def test_old_quarter_split_reproduces_one_physical_pixel_overflow(self):
        total = sum(tile_width(2560, p, 12, 2, 1.5) for p in (0.25, 0.75)) + 36
        self.assertAlmostEqual((total - 2560) * 1.5, 1)

    def test_overflow_does_not_center_and_hide_the_neighbor(self):
        self.assertIn('center-focused-column "never"', LAYOUT)
        self.assertIn("always-center-single-column", LAYOUT)

    def test_half_width_default_and_reset(self):
        self.assertIn("default-column-width { proportion 0.5; }", LAYOUT)
        self.assertRegex(KEYBOARD, r'Mod\+Alt\+R[^\n]*\{ set-column-width "50%"; \}')
