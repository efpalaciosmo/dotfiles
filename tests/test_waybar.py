"""Waybar keeps icon accents separate from escaped status text and HiDPI sizing."""

import json
import os
import re
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WAYBAR = ROOT / "packages/waybar/.config/waybar"
CONFIG = json.loads((WAYBAR / "config.jsonc").read_text())


class WaybarTests(unittest.TestCase):
    def run_status(self, name, stubs=None, values=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for command, body in (stubs or {}).items():
                stub = root / command
                stub.write_text("#!/bin/sh\n" + body)
                stub.chmod(0o755)
            env = {**os.environ, "PATH": f"{root}:{os.environ['PATH']}",
                   "XDG_RUNTIME_DIR": directory, **(values or {})}
            result = subprocess.run([str(WAYBAR / "scripts" / name)], env=env,
                                    text=True, capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            return json.loads(result.stdout)

    def test_logical_bar_size_and_existing_background_are_preserved(self):
        self.assertEqual(CONFIG["height"], 41)
        self.assertEqual(CONFIG["tray"]["icon-size"], 19)
        style = (WAYBAR / "style.css").read_text()
        self.assertIn("font-size: 15px", style)
        self.assertIn('font-family: "JetBrainsMono Nerd Font", "JetBrains Mono", monospace;', style)
        self.assertIn("@define-color surface #222226", style)
        self.assertRegex(style, r"window#waybar\s*\{\s*background: @surface;")

    def test_icon_markup_is_valid_and_dynamic_text_is_escaped(self):
        for name in ("custom/media", "custom/network-speed", "custom/cpu"):
            module = CONFIG[name]
            self.assertTrue(module["escape"], name)
            self.assertEqual(module["format"], "{icon}  {text}")
            for icon in module["format-icons"].values():
                element = ET.fromstring(icon)
                self.assertEqual(element.tag, "span")
                self.assertRegex(element.attrib["color"], r"^#[0-9a-f]{6}$")
        self.assertTrue(CONFIG["custom/media"]["hide-empty-text"])
        # Critical text/icons must remain dark on the light red warning surface.
        self.assertIn("#1d1d20", CONFIG["custom/cpu"]["format-icons"]["critical"])
        self.assertNotIn("<span", CONFIG["memory"]["format-critical"])

    def test_media_metadata_stays_plain_and_state_selects_the_icon(self):
        playerctl = '''case "$*" in
    status) printf '%s\\n' "$STATUS" ;;
    'metadata title') printf '%s\\n' 'A <song> & "title"' ;;
    'metadata artist') printf '%s\\n' 'Artist & guest' ;;
    'metadata album') printf '%s\\n' 'Album <live>' ;;
    *) printf '%s\\n' 'Test player' ;;
esac
'''
        for status, expected in (("Playing", "playing"), ("Paused", "paused"),
                                 ("Stopped", "stopped")):
            data = self.run_status("media-status", {"playerctl": playerctl},
                                   {"STATUS": status})
            self.assertEqual(data["alt"], expected)
            self.assertEqual(data["class"], expected)
            self.assertEqual(data["text"], 'Artist & guest - A <song> & "title"')
            self.assertIn("Album <live>", data["tooltip"])
            self.assertIn(expected, CONFIG["custom/media"]["format-icons"])

    def test_missing_media_title_hides_the_module(self):
        data = self.run_status("media-status", {"playerctl": "exit 0\n"})
        self.assertEqual(data["text"], "")
        self.assertEqual(data["class"], "stopped")

    def test_network_offline_uses_error_icon(self):
        data = self.run_status("network-speed", {"ip": "exit 0\n"})
        self.assertEqual(data["text"], "offline")
        self.assertEqual(data["class"], "disconnected")
        self.assertEqual(data["alt"], "disconnected")

    @unittest.skipUnless(Path("/sys/class/net/lo/statistics/rx_bytes").exists(),
                         "Linux network statistics required")
    def test_network_text_and_tooltip_support_special_characters(self):
        data = self.run_status("network-speed", {
            "ip": "echo 'default dev lo'\n",
            "nmcli": "printf 'Office & <lab>\\tVPN\\n'\n",
        })
        self.assertEqual(data["alt"], "ethernet")
        self.assertEqual(data["text"], "↓0.0 ↑0.0 Mb/s")
        self.assertIn("Office & <lab>\tVPN", data["tooltip"])
        self.assertEqual(data["class"], "connected")

    @unittest.skipUnless(Path("/proc/stat").exists(), "Linux CPU statistics required")
    def test_cpu_state_selects_icon_without_embedding_markup(self):
        data = self.run_status("cpu-status")
        self.assertTrue(re.fullmatch(r"\d+%", data["text"]))
        self.assertEqual(data["alt"], data["class"])
        self.assertIn(data["alt"], CONFIG["custom/cpu"]["format-icons"])


class AudioPickerTests(unittest.TestCase):
    SCRIPT = ROOT / "packages/fuzzel/.config/fuzzel/scripts/audio"

    def test_waybar_opens_the_output_and_microphone_pickers(self):
        self.assertIn("pulseaudio#mic", CONFIG["modules-right"])
        self.assertTrue(CONFIG["pulseaudio"]["on-click"].endswith("scripts/audio sink"))
        self.assertTrue(CONFIG["pulseaudio#mic"]["on-click"].endswith("scripts/audio source"))
        self.assertIn("@DEFAULT_AUDIO_SINK@", CONFIG["pulseaudio"]["on-click-middle"])
        self.assertIn("@DEFAULT_AUDIO_SOURCE@", CONFIG["pulseaudio#mic"]["on-click-middle"])

    def test_picker_marks_current_device_hides_pro_outputs_and_sets_default(self):
        nodes = json.dumps([
            {"id": i, "type": "PipeWire:Interface:Node", "info": {"props": {
                "media.class": "Audio/Sink", "node.name": name, "node.description": desc}}}
            for i, name, desc in (
                (45, "alsa_output.pci-1.pro-output-3", "Pro 3"),
                (57, "alsa_output.pci-2.analog-stereo", "Analog"),
                (61, "alsa_output.pci-3.hdmi-stereo", "Monitor HDMI"))])
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            stubs = {
                "pw-dump": f"cat <<'JSON'\n{nodes}\nJSON\n",
                "fuzzel": 'cat >"$ROOT/menu"\ngrep Monitor "$ROOT/menu"\n',
                "pactl": 'case "$1" in get-default-sink) echo alsa_output.pci-2.analog-stereo;; '
                         'list) ;; esac\n',
                "wpctl": 'echo "$@" >"$ROOT/wpctl"\n',
                "notify-send": "exit 0\n",
            }
            for command, body in stubs.items():
                stub = root / command
                stub.write_text("#!/bin/sh\n" + body)
                stub.chmod(0o755)
            env = {**os.environ, "PATH": f"{root}:{os.environ['PATH']}", "ROOT": directory}
            result = subprocess.run([str(self.SCRIPT), "sink"], env=env, text=True,
                                    capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            menu = (root / "menu").read_text().splitlines()
            self.assertEqual(menu, ["●  Analog", "   Monitor HDMI"])
            self.assertEqual((root / "wpctl").read_text().strip(), "set-default 61")

    def test_picker_rejects_unknown_mode(self):
        result = subprocess.run([str(self.SCRIPT), "bogus"], text=True,
                                capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 2)
