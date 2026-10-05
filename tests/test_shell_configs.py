"""The CachyOS shell package includes the opt-in Fedora container helpers."""

import tomllib
import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]


class ShellConfigTests(unittest.TestCase):
    def test_starship_palette_and_prompt(self):
        config = tomllib.loads((ROOT / "packages/starship/.config/starship.toml").read_text())
        self.assertEqual(config["palette"], "adwaita")
        self.assertIn("$git_status", config["format"])
        self.assertIn("$python", config["right_format"])
        self.assertEqual(config["palettes"]["adwaita"]["blue"], "#81d0ff")

    def test_zsh_init_and_container_are_opt_in(self):
        zshrc = (ROOT / "packages/shell-container/.zshrc").read_text()
        self.assertIn('eval "$(starship init zsh)"', zshrc)
        self.assertIn("autoload -Uz compinit", zshrc)
        self.assertIn("CONTAINER_ID:-} == fedora", zshrc)
        self.assertIn("DEEPSEEK_API_KEY:?", zshrc)
        fedora_terminal = ROOT / "packages/shell-container/.local/bin/fedora-terminal"
        self.assertTrue(fedora_terminal.stat().st_mode & 0o111)

    def test_shell_and_theme_are_both_linked_by_setup(self):
        play = yaml.safe_load((ROOT / "setup.yml").read_text())[0]
        packages = play["vars"]["dotfile_packages"]
        self.assertIn("shell-container", packages)
        self.assertIn("starship", packages)
        self.assertIn("starship", (ROOT / "Makefile").read_text())


if __name__ == "__main__":
    unittest.main()
