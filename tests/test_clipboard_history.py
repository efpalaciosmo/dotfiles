"""Clipboard data must remain in the user's ephemeral runtime directory."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "packages/fuzzel/.config/fuzzel/scripts/clipboard-history"


class ClipboardHistoryTests(unittest.TestCase):
    def test_sensitive_and_empty_selection_states_are_never_recorded(self):
        for state in ("sensitive", "nil", "clear"):
            with self.subTest(state=state), tempfile.TemporaryDirectory() as directory:
                env = {**os.environ, "XDG_RUNTIME_DIR": directory, "CLIPBOARD_STATE": state}
                subprocess.run([str(SCRIPT), "store", "text"], input=b"password", env=env, check=True)
                self.assertEqual(list(Path(directory).iterdir()), [])

    def test_symlinked_history_directory_cannot_redirect_private_data(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            runtime, outside = root / "runtime", root / "outside"
            runtime.mkdir(mode=0o700)
            outside.mkdir()
            (runtime / "dotfiles").symlink_to(outside)
            env = {**os.environ, "XDG_RUNTIME_DIR": str(runtime)}
            result = subprocess.run([str(SCRIPT), "store", "text"], input=b"password", env=env, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(list(outside.iterdir()), [])

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

    def test_repairs_existing_directory_and_database_permissions(self):
        with tempfile.TemporaryDirectory() as directory:
            runtime = Path(directory)
            folder = runtime / 'dotfiles/clipboard'
            folder.mkdir(parents=True)
            env = {**os.environ, 'XDG_RUNTIME_DIR': directory}
            subprocess.run([str(SCRIPT), 'store', 'text'], input=b'secret', env=env, check=True)
            database = folder / 'history.sqlite3'
            for path in (folder.parent, folder):
                path.chmod(0o755)
            database.chmod(0o644)
            subprocess.run([str(SCRIPT), 'list'], env=env, check=True, capture_output=True)
            self.assertEqual(folder.parent.stat().st_mode & 0o777, 0o700)
            self.assertEqual(folder.stat().st_mode & 0o777, 0o700)
            self.assertEqual(database.stat().st_mode & 0o777, 0o600)


if __name__ == "__main__":
    unittest.main()
