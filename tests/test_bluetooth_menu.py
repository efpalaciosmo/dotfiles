"""Exercise service and radio handling without accessing Bluetooth hardware."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "packages/fuzzel/.config/fuzzel/scripts/bluetooth"


class BluetoothMenuTests(unittest.TestCase):
    def run_menu(self, soft="unblocked", hard="unblocked", service="0"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            stubs = {
                "systemctl": 'exit "$SERVICE_STATUS"',
                "notify-send": "exit 0",
                "fuzzel": 'cat >/dev/null\nif [ ! -f "$STATE" ]; then printf "Activar Bluetooth\\n"; fi',
                "rfkill": 'printf "%s\\n" "$*" >>"$LOG"\ncase "$*" in *HARD*) echo "$HARD";; *SOFT*) echo "$SOFT";; esac',
                "bluetoothctl": 'printf "%s\\n" "$*" >>"$LOG"\ncase "$*" in *show*) echo "Controller 00:11:22:33:44:55"; if [ -f "$STATE" ]; then echo "Powered: yes"; else echo "Powered: no"; fi;; *"power on"*) touch "$STATE";; esac',
            }
            for name, body in stubs.items():
                stub = root / name
                stub.write_text("#!/bin/sh\n" + body + "\n")
                stub.chmod(0o755)
            env = {**os.environ, "PATH": directory + ":" + os.environ["PATH"],
                   "SOFT": soft, "HARD": hard, "SERVICE_STATUS": service,
                   "STATE": str(root / "powered"), "LOG": str(root / "calls")}
            result = subprocess.run([str(SCRIPT)], env=env, text=True, capture_output=True, timeout=5)
            calls = (root / "calls").read_text() if (root / "calls").exists() else ""
            return result, calls

    def test_unblocked_radio_is_not_unblocked_again(self):
        result, calls = self.run_menu()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("unblock bluetooth", calls)
        self.assertIn("power on", calls)

    def test_soft_block_is_cleared_before_power_on(self):
        result, calls = self.run_menu(soft="blocked")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertLess(calls.index("unblock bluetooth"), calls.index("power on"))

    def test_hard_block_has_actionable_error(self):
        result, calls = self.run_menu(hard="blocked")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("bloqueado por hardware", result.stderr)
        self.assertNotIn("power on", calls)

    def test_inactive_service_reports_workflow_repair_before_dbus_calls(self):
        result, calls = self.run_menu(service="3")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("make services", result.stderr)
        self.assertEqual(calls, "")
