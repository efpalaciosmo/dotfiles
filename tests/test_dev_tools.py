"""Claude Code, opencode, Vim, fastfetch, btop and git share the desktop's palette."""

import json
import os
import re
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGES = ROOT / "packages"
CLAUDE = PACKAGES / "claude/.claude"
OPENCODE = PACKAGES / "opencode/.config/opencode"

# Palette from docs/adwaita-theme.md; every themed tool must use it.
PALETTE = {"#1d1d20", "#222226", "#36363a", "#45454a", "#4b4b50", "#ff7800", "#ff9c5b",
           "#ffffff", "#c0bfbc", "#9a9996"}


# Every color a tool may use: the palette plus Ghostty's ANSI/semantic colors.
ANSI_AND_PALETTE = PALETTE | {"#8ff0a4", "#99c1f1", "#7bdff4", "#dc8add", "#ffc252", "#ff938c",
                              "#ffbe6f", "#f9f06b", "#77767b", "#5e5c64"}


class PackageRegistrationTests(unittest.TestCase):
    def test_new_packages_are_default_stow_packages(self):
        defaults = (ROOT / "Makefile").read_text().split("PACKAGES :=", 1)[1].splitlines()[0].split()
        for package in ("fastfetch", "btop", "claude", "opencode"):
            with self.subTest(package=package):
                self.assertIn(package, defaults)
                self.assertTrue((PACKAGES / package).is_dir())

    def test_credentials_and_tool_state_are_never_in_the_repository(self):
        forbidden = {".credentials.json", "service.json", "history.jsonl", "opencode.db"}
        found = [p for p in PACKAGES.rglob("*") if p.is_file() and p.name in forbidden]
        self.assertEqual(found, [])
        ignored = (ROOT / ".gitignore").read_text()
        for name in (".credentials.json", "service.json"):
            self.assertIn(name, ignored)


class ClaudeTests(unittest.TestCase):
    settings = json.loads((CLAUDE / "settings.json").read_text())

    def test_terminal_theme_follows_the_ghostty_palette(self):
        # Custom Claude themes only draw in the desktop/mobile apps; in a terminal
        # the ANSI theme inherits Ghostty's Adwaita palette.
        self.assertEqual(self.settings["theme"], "dark-ansi")

    def test_existing_user_settings_are_preserved(self):
        self.assertEqual(self.settings["model"], "sonnet")
        self.assertIn("power-platform-skills", self.settings["extraKnownMarketplaces"])
        self.assertTrue(self.settings["enabledPlugins"]["dataverse@power-platform-skills"])
        self.assertEqual(self.settings["modelSettings"]["claude-sonnet-5-5"]["effortLevel"], "high")

    def test_credential_files_are_denied_and_never_allowed(self):
        deny = " ".join(self.settings["permissions"]["deny"])
        for path in (".credentials.json", "service.json", ".ssh", ".gnupg", ".env"):
            self.assertIn(path, deny)
        for rule in self.settings["permissions"]["allow"]:
            self.assertTrue(rule.startswith("Bash(git ") or rule.startswith("Bash(make ")
                            or rule.startswith("Bash(niri "), rule)

    def test_scripts_are_executable_and_referenced(self):
        for relative, key in (("statusline.sh", "statusLine"), ("hooks/notify.sh", "hooks")):
            path = CLAUDE / relative
            self.assertTrue(os.access(path, os.X_OK), relative)
            self.assertIn(Path(relative).name, json.dumps(self.settings[key]))

    def test_statusline_shows_directory_model_and_context_with_palette_colors(self):
        payload = json.dumps({"workspace": {"current_dir": str(ROOT)}, "model": {"display_name": "Test 1"},
                              "context_window": {"used_percentage": 91.2}})
        out = subprocess.run([str(CLAUDE / "statusline.sh")], input=payload, text=True,
                             capture_output=True, check=True).stdout
        plain = re.sub(r"\x1b\[[0-9;]*m", "", out)
        self.assertIn("Test 1", plain)
        self.assertIn("ctx 91%", plain)
        self.assertIn("255;156;91", out)   # directory in #ff9c5b
        self.assertIn("255;147;140", out)  # nearly-full context in error red

    def test_statusline_survives_empty_input(self):
        result = subprocess.run([str(CLAUDE / "statusline.sh")], input="{}", text=True, capture_output=True)
        self.assertEqual(result.returncode, 0)
        self.assertTrue(result.stdout.strip())

    def test_notify_hook_sends_a_mako_notification_and_never_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            stub = Path(directory) / "notify-send"
            stub.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$LOG"\n')
            stub.chmod(0o755)
            env = {**os.environ, "PATH": f"{directory}:{os.environ['PATH']}", "LOG": f"{directory}/log"}
            payload = json.dumps({"message": "Needs permission", "cwd": "/home/x/project"})
            result = subprocess.run([str(CLAUDE / "hooks/notify.sh")], input=payload, text=True, env=env)
            self.assertEqual(result.returncode, 0)
            lines = (Path(directory) / "log").read_text().splitlines()
            self.assertIn("Claude Code", lines)
            self.assertIn("Claude Code · project", lines)
            self.assertIn("Needs permission", lines)

    def test_global_instructions_exist_for_both_agents(self):
        text = (CLAUDE / "CLAUDE.md").read_text()
        self.assertIn("#ff7800", text)
        self.assertIn("opencode", text)


class OpencodeTests(unittest.TestCase):
    theme = json.loads((OPENCODE / "themes/adwaita-orange.json").read_text())

    def test_cli_selects_the_theme_and_config_has_no_secrets(self):
        cli = json.loads((OPENCODE / "cli.json").read_text())
        self.assertEqual(cli["theme"]["name"], "adwaita-orange")
        config = (OPENCODE / "opencode.json").read_text()
        self.assertNotIn("password", config.lower())
        self.assertFalse((OPENCODE / "service.json").exists())

    def test_theme_declares_the_required_hues_and_every_step(self):
        hue = self.theme["dark"]["hue"]
        for semantic in ("accent", "interactive", "neutral"):
            self.assertTrue(hue[semantic].startswith("$hue."), semantic)
        for name in ("gray", "red", "orange", "yellow", "green", "cyan", "blue", "purple"):
            self.assertEqual(sorted(hue[name]), [str(step) for step in range(100, 1000, 100)], name)
            for value in hue[name].values():
                self.assertRegex(value, r"^#[0-9a-f]{6}$")

    def test_theme_has_the_complete_base_token_tree(self):
        base = self.theme["base"]
        self.assertTrue(base["categorical"])
        self.assertEqual(set(base["text"]["action"]), {"primary", "secondary", "destructive"})
        self.assertEqual(set(base["background"]["raised"]), {"base", "high", "max"})
        self.assertEqual(set(base["background"]["feedback"]), {"error", "warning", "success", "info"})
        self.assertEqual(set(base["syntax"]), {"comment", "keyword", "function", "variable", "string",
                                               "number", "type", "operator", "punctuation"})
        self.assertEqual(len(base["markdown"]), 14)
        self.assertEqual(base["background"]["base"], "#1d1d20")
        self.assertEqual(base["background"]["action"]["primary"]["base"], "#ff7800")


class EditorAndToolThemeTests(unittest.TestCase):
    def test_vim_uses_the_desktop_palette(self):
        scheme = (PACKAGES / "vi/.vim/colors/adwaita-orange.vim").read_text().lower()
        for color in PALETTE:
            self.assertIn(color, scheme, color)
        self.assertIn("colorscheme adwaita-orange", (PACKAGES / "vi/.vimrc").read_text())

    def test_neovim_and_tmux_are_not_managed(self):
        for package in ("nvim", "tmux"):
            self.assertFalse((PACKAGES / package).exists(), package)
        makefile = (ROOT / "Makefile").read_text().split("PACKAGES :=", 1)[1].splitlines()[0].split()
        self.assertFalse({"nvim", "tmux"} & set(makefile))
        for name in ("vi/.vimrc", "vi/.vim/colors/adwaita-orange.vim", "shell-container/.zshrc",
                     "shell-container/.bashrc"):
            text = (PACKAGES / name).read_text().lower()
            self.assertNotIn("nvim", text, name)
            self.assertNotIn("tmux", text, name)

    def test_ansi_palette_matches_between_ghostty_and_vim(self):
        theme = (PACKAGES / "ghostty/.config/ghostty/themes/Adwaita Dark Orange").read_text()
        ansi = re.findall(r"palette = \d+=(#[0-9a-f]{6})", theme)
        scheme = (PACKAGES / "vi/.vim/colors/adwaita-orange.vim").read_text().lower()
        for color in ansi:
            self.assertIn(color, scheme, color)

    def test_btop_theme_and_config(self):
        theme = (PACKAGES / "btop/.config/btop/themes/adwaita-orange.theme").read_text()
        self.assertIn('theme[main_bg]="#1d1d20"', theme)
        self.assertIn('theme[upload_start]="#ff7800"', theme)
        config = (PACKAGES / "btop/.config/btop/btop.conf").read_text()
        self.assertIn('color_theme = "adwaita-orange"', config)
        self.assertIn("vim_keys = True", config)

    def test_fastfetch_config_is_valid_and_uses_the_accent(self):
        path = PACKAGES / "fastfetch/.config/fastfetch/config.jsonc"
        config = json.loads(path.read_text())
        self.assertIn("255;120;0", json.dumps(config))
        types = [m["type"] for m in config["modules"] if isinstance(m, dict)]
        for module in ("os", "kernel", "cpu", "gpu", "memory", "disk", "display", "wm"):
            self.assertIn(module, types)
        disk = next(m for m in config["modules"] if isinstance(m, dict) and m["type"] == "disk")
        self.assertIn("/", disk["hideFolders"].split(":"), "read-only overlay root is noise")

    def test_gitconfig_has_no_stale_temporary_credential_helper(self):
        for line in (PACKAGES / "git/.gitconfig").read_text().splitlines():
            if not line.lstrip().startswith("#"):
                self.assertNotIn("/tmp/", line)
                self.assertNotIn("credential", line)
        self.assertIn("autoSetupRemote", (PACKAGES / "git/.gitconfig").read_text())


if __name__ == "__main__":
    unittest.main()
