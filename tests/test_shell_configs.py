"""The shell package includes the opt-in Fedora container helpers."""

import shutil
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path


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
        self.assertIn("starship init zsh", zshrc)
        self.assertIn("autoload -Uz compinit", zshrc)
        self.assertIn("alias fedora='distrobox enter fedora -- zsh'", zshrc)
        # Entering the container must never start a multiplexer on its own.
        self.assertNotIn("tmux", zshrc)
        fedora_terminal = ROOT / "packages/shell-container/.local/bin/fedora-terminal"
        self.assertTrue(fedora_terminal.stat().st_mode & 0o111)

    def test_zsh_uses_user_local_oh_my_zsh_with_both_plugins(self):
        zshrc = (ROOT / "packages/shell-container/.zshrc").read_text()
        self.assertIn('export ZSH="$HOME/.oh-my-zsh"', zshrc)
        self.assertIn("plugins+=(zsh-autosuggestions)", zshrc)
        self.assertIn("plugins+=(zsh-syntax-highlighting)", zshrc)
        # Highlighting has to be the last plugin, and updates are owned by the installer.
        self.assertLess(zshrc.index("plugins+=(zsh-autosuggestions)"),
                        zshrc.index("plugins+=(zsh-syntax-highlighting)"))
        self.assertIn("zstyle ':omz:update' mode disabled", zshrc)

    @unittest.skipUnless(shutil.which("zsh"), "zsh unavailable")
    def test_zshrc_loads_in_a_clean_home_without_noise(self):
        with tempfile.TemporaryDirectory() as home:
            result = subprocess.run(
                ["zsh", "-f", "-c", f"HOME={home}; source {ROOT}/packages/shell-container/.zshrc"],
                capture_output=True, text=True, env={"PATH": "/usr/bin:/bin", "HOME": home})
        self.assertEqual(result.returncode, 0, result.stderr)
        # Missing optional tools must not print errors; only the Starship hint is allowed.
        self.assertNotIn("command not found", result.stderr)
        self.assertNotIn("no such file", result.stderr.lower())

    def test_shell_and_theme_are_both_linked_by_setup(self):
        makefile = (ROOT / "Makefile").read_text()
        packages = makefile.split("PACKAGES :=", 1)[1].splitlines()[0].split()
        self.assertIn("shell-container", packages)
        self.assertIn("starship", packages)
        self.assertIn("starship", (ROOT / "Makefile").read_text())


if __name__ == "__main__":
    unittest.main()
