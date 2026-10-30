"""GNOME login preferences and display plans without touching the live desktop."""

import copy
import contextlib
import io
import os
import runpy
import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "packages/gnome/.local/bin/dotfiles-gnome"
GNOME = runpy.run_path(str(SCRIPT))


def monitor(connector="DP-1", width=3840, height=2160, scales=None):
    spec = (connector, "AUS", "VG27UQ1A", "test-serial")
    mode = (f"{width}x{height}@59.997", width, height, 59.997, 1.5,
            [1.0, 1.5, 2.0] if scales is None else scales, {"is-current": True})
    return (spec, [mode], {"is-underscanning": False, "color-mode": 0})


def state(scale=1.3333333730697632, transform=0):
    physical = monitor()
    return (3, [physical], [(0, 0, scale, transform, True, [physical[0]], {})],
            {"layout-mode": 1, "supports-changing-layout-mode": True})


class MemoryPreferences:
    def __init__(self):
        self.values = {("org.gnome.settings-daemon.plugins.media-keys", "custom-keybindings", None):
                       ["/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/personal/"],
                       (GNOME["WM_KEYBINDINGS"], "close", None): ["<Alt>F4"],
                       (GNOME["WM_KEYBINDINGS"], "toggle-maximized", None): ["<Alt>F10"],
                       (GNOME["WM_KEYBINDINGS"], "switch-to-workspace-1", None): ["<Super>Home"],
                       (GNOME["MUTTER_KEYBINDINGS"], "toggle-tiled-left", None): ["<Super>Left"],
                       (GNOME["MUTTER_KEYBINDINGS"], "toggle-tiled-right", None): ["<Super>Right"]}

    def get(self, schema, key, path=None):
        if schema in (GNOME["WM_KEYBINDINGS"], GNOME["MUTTER_KEYBINDINGS"]):
            return self.values.get((schema, key, path), [])
        return self.values[(schema, key, path)]

    def set(self, schema, key, value, path=None):
        self.values[(schema, key, path)] = value


class GnomeTests(unittest.TestCase):
    def test_four_workspaces_and_shortcuts_preserve_existing_custom_bindings(self):
        store = MemoryPreferences()
        GNOME["configure_preferences"](store)
        original = copy.deepcopy(store.values)
        GNOME["configure_preferences"](store)
        self.assertEqual(store.values, original)
        self.assertFalse(store.get("org.gnome.mutter", "dynamic-workspaces"))
        self.assertEqual(store.get("org.gnome.desktop.wm.preferences", "num-workspaces"), 4)
        for number in range(1, 5):
            self.assertIn(f"<Super>{number}", store.get(GNOME["WM_KEYBINDINGS"], f"switch-to-workspace-{number}"))
            self.assertEqual(store.get("org.gnome.shell.keybindings", f"switch-to-application-{number}"), [])
            self.assertEqual(store.get("org.gnome.desktop.wm.keybindings", f"move-to-workspace-{number}"),
                             [f"<Super><Shift>{number}", f"<Super><Control>{number}"])
        self.assertIn("<Super>Home", store.get(GNOME["WM_KEYBINDINGS"], "switch-to-workspace-1"))
        self.assertEqual(len(store.get("org.gnome.settings-daemon.plugins.media-keys", "custom-keybindings")), 2)
        self.assertEqual(store.get(GNOME["CUSTOM_SCHEMA"], "command", GNOME["TERMINAL_PATH"]), "ghostty")
        self.assertEqual(store.get(GNOME["CUSTOM_SCHEMA"], "binding", GNOME["TERMINAL_PATH"]), "<Super>Return")

    def test_niri_like_window_actions_keep_native_gnome_aliases(self):
        store = MemoryPreferences()
        GNOME["configure_window_shortcuts"](store)
        for key, expected in {
            "close": ["<Alt>F4", "<Super>q"],
            "toggle-maximized": ["<Alt>F10", "<Super>f"],
            "toggle-fullscreen": ["<Super><Shift>f"],
            "move-to-center": ["<Super>c"],
            "switch-to-workspace-right": ["<Super>u"],
            "switch-to-workspace-left": ["<Super>i"],
            "move-to-workspace-right": ["<Super><Control>u"],
            "move-to-workspace-left": ["<Super><Control>i"],
            "move-to-monitor-left": ["<Super><Control><Shift>h"],
            "move-to-monitor-down": ["<Super><Control><Shift>j"],
            "move-to-monitor-up": ["<Super><Control><Shift>k"],
            "move-to-monitor-right": ["<Super><Control><Shift>l"],
        }.items():
            self.assertEqual(store.get(GNOME["WM_KEYBINDINGS"], key), expected, key)
        for side, key in (("Left", "h"), ("Right", "l")):
            self.assertEqual(store.get(GNOME["MUTTER_KEYBINDINGS"], f"toggle-tiled-{side.lower()}"),
                             [f"<Super>{side}", f"<Super><Control>{key}"])

    def test_personal_window_aliases_survive_reapplication_without_duplicates(self):
        store = MemoryPreferences()
        store.set(GNOME["WM_KEYBINDINGS"], "close", ["<Alt>F4", "<Super>q", "<Control><Alt>q"])
        GNOME["configure_preferences"](store)
        before = copy.deepcopy(store.values)
        GNOME["configure_preferences"](store)
        self.assertEqual(store.values, before)
        self.assertEqual(store.get(GNOME["WM_KEYBINDINGS"], "close"),
                         ["<Alt>F4", "<Super>q", "<Control><Alt>q"])
        # Do not steal GNOME lock/minimize/notification or application cycling keys.
        self.assertNotIn((GNOME["WM_KEYBINDINGS"], "minimize", None), store.values)
        self.assertNotIn((GNOME["WM_KEYBINDINGS"], "switch-applications", None), store.values)
        self.assertNotIn(("org.gnome.shell.keybindings", "toggle-message-tray", None), store.values)

    def test_added_shortcuts_have_no_duplicate_action_assignments(self):
        store = MemoryPreferences()
        GNOME["configure_preferences"](store)
        actions = {}
        for (schema, key, _), shortcuts in store.values.items():
            if schema not in (GNOME["WM_KEYBINDINGS"], GNOME["MUTTER_KEYBINDINGS"]):
                continue
            for shortcut in shortcuts:
                self.assertNotIn(shortcut, actions, f"{shortcut}: {key} conflicts with {actions.get(shortcut)}")
                actions[shortcut] = key

    def test_150_percent_preserves_resolution_refresh_transform_and_color(self):
        original = state(transform=1)
        before = copy.deepcopy(original)
        serial, logical, _ = GNOME["display_plan"](original)
        self.assertEqual(original, before)
        self.assertEqual(serial, 3)
        self.assertEqual(logical, [(0, 0, 1.5, 1, True,
                                   [("DP-1", "3840x2160@59.997", {"underscanning": False, "color-mode": 0})])])

    def test_already_scaled_or_no_active_4k_needs_no_modeset(self):
        self.assertIsNone(GNOME["display_plan"](state(scale=1.5)))
        self.assertIsNone(GNOME["display_plan"]((3, [], [], {})))
        physical = monitor(width=1920, height=1080)
        self.assertIsNone(GNOME["display_plan"]((3, [physical],
                          [(0, 0, 1.0, 0, True, [physical[0]], {})], {})))

    def test_mixed_dpi_preserves_the_other_monitor(self):
        serial, physical, logical, props = state(scale=2.0)
        other = monitor("HDMI-1", 1920, 1080)
        physical.append(other)
        logical.append((-1920, 0, 1.0, 0, False, [other[0]], {}))
        _, result, _ = GNOME["display_plan"]((serial, physical, logical, props))
        self.assertEqual(result[0][2], 1.5)
        self.assertEqual(result[1][:5], (-1920, 0, 1.0, 0, False))

    def test_unsupported_scale_and_overlapping_layout_are_refused(self):
        original = state()
        original[1][0][1][0][5].remove(1.5)
        with self.assertRaisesRegex(RuntimeError, "150% is unavailable"):
            GNOME["display_plan"](original)
        serial, physical, logical, props = state(scale=2.0)
        other = monitor("HDMI-1", 1920, 1080)
        physical.append(other)
        logical.append((1920, 0, 1.0, 0, False, [other[0]], {}))
        with self.assertRaisesRegex(RuntimeError, "overlap"):
            GNOME["display_plan"]((serial, physical, logical, props))

    def test_display_apply_verifies_before_persisting_and_is_idempotent(self):
        for scale in (1.3333333730697632, 1.5):
            calls = []

            def call(method, parameters, *args):
                calls.append((method, parameters))
                return SimpleNamespace(unpack=lambda: state(scale=scale))

            proxy = SimpleNamespace(call_sync=call)
            Gio = SimpleNamespace(
                DBusProxy=SimpleNamespace(new_for_bus_sync=lambda *args: proxy),
                BusType=SimpleNamespace(SESSION=0),
                DBusProxyFlags=SimpleNamespace(DO_NOT_AUTO_START=0),
                DBusCallFlags=SimpleNamespace(NONE=0))
            GLib = SimpleNamespace(Variant=lambda signature, value: (signature, value))
            with contextlib.redirect_stdout(io.StringIO()):
                GNOME["configure_displays"](Gio, GLib)
            if scale == 1.5:
                self.assertEqual([method for method, _ in calls], ["GetCurrentState"])
            else:
                self.assertEqual([method for method, _ in calls],
                                 ["GetCurrentState", "ApplyMonitorsConfig", "ApplyMonitorsConfig"])
                self.assertEqual([parameters[1][1] for _, parameters in calls[1:]], [0, 2])
                self.assertEqual(calls[1][1][0], "(uua(iiduba(ssa{sv}))a{sv})")

    def test_non_gnome_login_never_touches_preferences_or_displays(self):
        result = subprocess.run(["python3", str(SCRIPT)], capture_output=True, text=True,
                                env={**os.environ, "XDG_CURRENT_DESKTOP": "niri"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("skipped", result.stdout)

    def test_login_entry_is_gnome_only_and_uses_the_managed_helper(self):
        entry = (ROOT / "packages/gnome/.config/autostart/dotfiles-gnome.desktop").read_text()
        self.assertIn("OnlyShowIn=GNOME;", entry)
        self.assertIn("~/.local/bin/dotfiles-gnome", entry)
        self.assertNotIn("waybar", entry)
        command = next(line.removeprefix("Exec=") for line in entry.splitlines() if line.startswith("Exec="))
        with tempfile.TemporaryDirectory(prefix="gnome home ") as directory:
            helper = Path(directory) / ".local/bin/dotfiles-gnome"
            helper.parent.mkdir(parents=True)
            helper.write_text("#!/bin/sh\necho login-helper\n")
            helper.chmod(0o755)
            result = subprocess.run(shlex.split(command), env={**os.environ, "HOME": directory},
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.strip(), "login-helper")
