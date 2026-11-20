"""Niri shortcuts follow one grammar and the Quick actions hub shows the real keys."""

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
KEYBOARD = (ROOT / "packages/niri/.config/niri/keyboard.kdl").read_text()
LAUNCHER = (ROOT / "packages/fuzzel/.config/fuzzel/scripts/launcher").read_text()


def binds():
    """Return {chord: full bind text} for every bind, ignoring comments."""
    result, lines = {}, KEYBOARD.splitlines()
    index = 0
    while index < len(lines):
        match = re.match(r"\s+([A-Z][\w]*(?:\+\w+)*)\b[^{]*\{", lines[index])
        if not match:
            index += 1
            continue
        chord, text, depth = match[1], [], 0
        while True:
            text.append(lines[index])
            depth += lines[index].count("{") - lines[index].count("}")
            index += 1
            if depth <= 0:
                break
        assert chord not in result, f"duplicate bind: {chord}"
        result[chord] = "\n".join(text)
    return result


def normalize(hint):
    return hint.replace("Super", "Mod").replace("+/", "+Slash")


class NiriKeybindTests(unittest.TestCase):
    def test_no_duplicate_chords(self):
        self.assertGreater(len(binds()), 60)

    def test_bluetooth_is_a_mod_shift_menu_not_a_bare_ctrl_chord(self):
        table = binds()
        self.assertNotIn("Ctrl+B", table)
        self.assertIn("fuzzel/scripts/bluetooth", table["Mod+Shift+B"])

    def test_files_shortcut_opens_yazi_with_the_app_id_the_float_rule_matches(self):
        bind = binds()["Mod+E"]
        self.assertIn('"yazi"', bind)
        self.assertIn("--class=org.dotfiles.Yazi", bind)
        self.assertIn("--confirm-close-surface=false", bind)
        self.assertNotIn("thunar", bind.lower())
        rules = (ROOT / "packages/niri/.config/niri/rules.kdl").read_text()
        self.assertIn(r'app-id=r#"^org\.dotfiles\.Yazi$"#', rules)

    def test_yazi_desktop_entry_is_the_folder_handler_with_the_same_app_id(self):
        entry = (ROOT / "packages/desktop/.local/share/applications/yazi.desktop").read_text()
        self.assertIn("MimeType=inode/directory;", entry)
        self.assertIn("--class=org.dotfiles.Yazi", entry)
        self.assertIn("StartupWMClass=org.dotfiles.Yazi", entry)
        self.assertIn("--confirm-close-surface=false", entry)
        self.assertIn("-e yazi", entry)

    def test_every_subsystem_menu_has_a_direct_shortcut(self):
        table = binds()
        expected = {
            "Mod+Shift+B": "scripts/bluetooth",
            "Mod+Shift+N": "scripts/wifi",
            "Mod+Shift+S": "scripts/screenshot",
            "Mod+Shift+Y": "scripts/clipboard",
            "Mod+Shift+P": "scripts/power-menu",
            "Mod+Shift+M": "terminal-tool monitor",
            "Mod+Shift+W": "launcher window",
            "Mod+Shift+D": "launcher actions",
            "Mod+X": "launcher run",
            "Mod+Slash": "launcher recursivebrowser",
            "Mod+D": "scripts/launcher\"",
        }
        for chord, command in expected.items():
            with self.subTest(chord=chord):
                self.assertIn(command, table[chord])

    def test_hub_hints_match_the_configured_bindings(self):
        table = binds()
        hints = re.findall(r'entry "[^"]+" "((?:Super\+)(?:Shift\+)?[^"]+)"', LAUNCHER)
        self.assertGreaterEqual(len(hints), 8)
        for hint in hints:
            with self.subTest(hint=hint):
                self.assertIn(normalize(hint), table)

    def test_every_launcher_bind_has_an_overlay_title(self):
        for chord, line in binds().items():
            if chord.startswith(("Mod+Shift+", "Mod+Alt+L")) and "spawn" in line \
                    and not re.search(r"Mod\+(Ctrl\+)?Shift\+[HJKL]$", chord):
                with self.subTest(chord=chord):
                    self.assertIn("hotkey-overlay-title=", line)


if __name__ == "__main__":
    unittest.main()
