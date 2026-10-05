"""Check lock/idle wiring without ever locking the test session."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPTS = Path(__file__).resolve().parents[1] / "packages/niri/.config/niri/scripts"


class NiriLockTests(unittest.TestCase):
    def test_lock_command_uses_swaylock_and_waits_for_surface(self):
        with tempfile.TemporaryDirectory() as directory:
            stub = Path(directory) / "swaylock"
            stub.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            stub.chmod(0o755)
            env = {**os.environ, "PATH": directory + ":" + os.environ["PATH"]}
            args = subprocess.check_output([str(SCRIPTS / "lock-screen")], env=env, text=True).splitlines()
            self.assertIn("-f", args)
            self.assertIn("-e", args)
            self.assertIn("222226", args)
            self.assertIn("--indicator-idle-visible", args)

    def test_lock_uses_wallpaper_and_config_with_spaces_and_colons(self):
        with tempfile.TemporaryDirectory() as directory:
            stub = Path(directory) / "swaylock"
            stub.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            stub.chmod(0o755)
            config = Path(directory) / "config with spaces:colon"
            lock_config = config / "swaylock/config"
            wallpaper = config / "niri/backgrounds/adwaita-dark.png"
            for path in (lock_config, wallpaper):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("appearance fixture")
            env = {**os.environ, "PATH": directory + ":" + os.environ["PATH"], "XDG_CONFIG_HOME": str(config)}
            args = subprocess.check_output([str(SCRIPTS / "lock-screen")], env=env, text=True).splitlines()
            self.assertEqual(args[args.index("-C") + 1], str(lock_config))
            self.assertEqual(args[args.index("--image") + 1], ":" + str(wallpaper))
            self.assertEqual(args[args.index("--scaling") + 1], "fill")

    def test_lock_still_runs_when_appearance_files_are_missing(self):
        with tempfile.TemporaryDirectory() as directory:
            stub = Path(directory) / "swaylock"
            stub.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            stub.chmod(0o755)
            env = {**os.environ, "PATH": directory + ":" + os.environ["PATH"],
                   "XDG_CONFIG_HOME": str(Path(directory) / "missing")}
            args = subprocess.check_output([str(SCRIPTS / "lock-screen")], env=env, text=True).splitlines()
            self.assertIn("-f", args)
            self.assertIn("222226", args)
            self.assertEqual(args[args.index("-C") + 1], "/dev/null")
            self.assertNotIn("--image", args)

    def test_idle_uses_one_lock_command_for_timeout_sleep_and_logind(self):
        with tempfile.TemporaryDirectory() as directory:
            stub = Path(directory) / "swayidle"
            stub.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            stub.chmod(0o755)
            config = str(Path(directory) / "config with spaces")
            env = {**os.environ, "PATH": directory + ":" + os.environ["PATH"], "XDG_CONFIG_HOME": config}
            args = subprocess.check_output([str(SCRIPTS / "session-idle")], env=env, text=True).splitlines()
            self.assertEqual(args[0:3], ["-w", "timeout", "300"])
            lock = args[3]
            self.assertIn("lock-screen", lock)
            self.assertIn("\\ ", lock)
            self.assertEqual(args[-1], lock)
            self.assertEqual(args[args.index("before-sleep") + 1], lock)
            self.assertEqual(args[args.index("lock") + 1], lock)
            self.assertEqual(args[args.index("timeout", 4) + 1], "600")
            self.assertEqual(args[args.index("after-resume") + 1], "niri msg action power-on-monitors")


if __name__ == "__main__":
    unittest.main()
