"""Clipboard data must remain in the user's ephemeral runtime directory."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "packages/fuzzel/.config/fuzzel/scripts/clipboard-history"


class ClipboardHistoryTests(unittest.TestCase):
    def test_session_storage_and_clear(self):
        with tempfile.TemporaryDirectory() as directory:
            runtime = Path(directory) / "runtime"
            runtime.mkdir(mode=0o700)
            env = {**os.environ, "XDG_RUNTIME_DIR": str(runtime), "XDG_DATA_HOME": str(Path(directory) / "persistent")}
            subprocess.run([str(SCRIPT), "store", "text"], input=b"private text", env=env, check=True)
            database = runtime / "dotfiles/clipboard/history.sqlite3"
            self.assertTrue(database.is_file())
            self.assertEqual(database.stat().st_mode & 0o777, 0o600)
            self.assertFalse(Path(env["XDG_DATA_HOME"]).exists())
            listing = subprocess.check_output([str(SCRIPT), "list"], env=env, text=True)
            self.assertIn("private text", listing)
            subprocess.run([str(SCRIPT), "clear"], env=env, check=True)
            self.assertEqual(subprocess.check_output([str(SCRIPT), "list"], env=env), b"")

    def test_no_persistent_fallback(self):
        with tempfile.TemporaryDirectory() as directory:
            env = {**os.environ, "XDG_DATA_HOME": directory}
            env.pop("XDG_RUNTIME_DIR", None)
            result = subprocess.run([str(SCRIPT), "store", "text"], input=b"private", env=env, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(b"XDG_RUNTIME_DIR", result.stderr)
            self.assertEqual(list(Path(directory).iterdir()), [])


if __name__ == "__main__":
    unittest.main()
