"""One default terminal across dotfiles, launcher, bindings and bar."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class GhosttyTests(unittest.TestCase):
    def test_theme_and_terminal_defaults_are_stow_packages(self):
        config = ROOT / "packages/ghostty/.config/ghostty/config.ghostty"
        entries = [line.split(" = ", 1) for line in config.read_text().splitlines() if line and not line.startswith("#")]
        values = dict(entries)
        self.assertEqual([value for key, value in entries if key == "font-family"],
                         ['""', "JetBrainsMono Nerd Font", "JetBrains Mono"])
        self.assertEqual(values["font-size"], "15")
        theme = config.parent / "themes" / values["theme"]
        self.assertTrue(theme.is_file())
        text = theme.read_text()
        self.assertIn("background = #1d1d20", text)
        self.assertIn("selection-background = #ff7800", text)
        self.assertEqual(text.count("palette = "), 16)
        self.assertIn("config-file = config.ghostty", (config.parent / "config").read_text())
        defaults = (ROOT / "Makefile").read_text().split("PACKAGES :=", 1)[1].splitlines()[0].split()
        self.assertIn("ghostty", defaults)
        self.assertNotIn("kitty", defaults)
        self.assertEqual((config.parent.parent / "xdg-terminals.list").read_text(),
                         "com.mitchellh.ghostty.desktop\n")
        self.assertIn('TERMINAL "ghostty"', (ROOT / "packages/niri/.config/niri/environment.kdl").read_text())
        self.assertIn('spawn "ghostty"', (ROOT / "packages/niri/.config/niri/keyboard.kdl").read_text())
        self.assertIn("terminal=ghostty -e", (ROOT / "packages/fuzzel/.config/fuzzel/fuzzel.ini").read_text())

    def test_waybar_passes_command_and_title_to_ghostty(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binary = root / "ghostty"
            binary.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$LOG"\n')
            binary.chmod(0o755)
            env = {**os.environ, "PATH": f"{root}:{os.environ['PATH']}", "LOG": str(root / "args")}
            result = subprocess.run([str(ROOT / "packages/waybar/.config/waybar/scripts/terminal-tool"), "calendar"],
                                    env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            arguments = (root / "args").read_text().splitlines()
            self.assertEqual(arguments[:4], ["--title=Calendar", "-e", "bash", "-lc"])
            self.assertTrue(arguments[4].startswith('cal -3; status=$?; printf "'))

    def test_validation_resolves_theme_from_repository_before_linking(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binary = root / "ghostty"
            binary.write_text('#!/bin/sh\nprintf "%s\\n" "$XDG_CONFIG_HOME" "$@" > "$LOG"\nexit 17\n')
            binary.chmod(0o755)
            env = {**os.environ, "PATH": f"{root}:{os.environ['PATH']}", "LOG": str(root / "args")}
            result = subprocess.run(["bash", str(ROOT / "scripts/validate-configs.sh"), "ghostty"], env=env)
            self.assertEqual(result.returncode, 17)
            self.assertEqual((root / "args").read_text().splitlines(), [
                str(ROOT / "packages/ghostty/.config"), "+validate-config",
                f"--config-file={ROOT}/packages/ghostty/.config/ghostty/config.ghostty",
            ])
