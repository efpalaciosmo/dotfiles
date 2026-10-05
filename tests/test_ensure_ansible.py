"""The Ansible bootstrap must use a user venv, never pacman or sudo."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/ensure-ansible.sh"


class EnsureAnsibleTests(unittest.TestCase):
    def test_other_distributions_stop_before_creating_venv(self):
        with tempfile.TemporaryDirectory() as directory:
            venv = Path(directory) / "venv"
            result = subprocess.run(
                ["bash", "-c", 'source "$1"; is_cachyos() { return 1; }; main system', "bash", str(SCRIPT)],
                env={**os.environ, "ANSIBLE_VENV": str(venv)}, capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(venv.exists())

    def test_missing_python_stops_without_installing_it(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            marker = root / "sudo-called"
            venv = root / "venv"
            for name in ("pacman", "sudo"):
                stub = root / name
                stub.write_text('#!/bin/sh\ntouch "$MARKER"\n')
                stub.chmod(0o755)
            env = {**os.environ, "PATH": directory + ":" + os.environ["PATH"],
                   "MARKER": str(marker), "ANSIBLE_VENV": str(venv)}
            command = (
                'source "$1"; is_cachyos() { return 0; }; '
                'command() { if [[ $1 == -v && $2 == python3 ]]; then return 1; fi; builtin command "$@"; }; '
                'main system'
            )
            result = subprocess.run(["bash", "-c", command, "bash", str(SCRIPT)], env=env, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(b"python3 is required", result.stderr)
            self.assertFalse(marker.exists())
            self.assertFalse(venv.exists())

    def test_creates_and_reuses_user_venv_without_sudo(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            venv = root / "venv"
            marker = root / "calls"
            fake_python = root / "python3"
            fake_python.write_text(
                '#!/bin/sh\nprintf "venv\\n" >> "$MARKER"\n'
                'mkdir -p "$3/bin"\n'
                'cat > "$3/bin/python" <<\'EOF\'\n'
                '#!/bin/sh\n'
                'if [ "$3" = "install" ]; then\n'
                '  printf "pip\\n" >> "$MARKER"\n'
                '  printf "#!/bin/sh\\n" > "$ANSIBLE_VENV/bin/ansible-playbook"\n'
                '  chmod +x "$ANSIBLE_VENV/bin/ansible-playbook"\n'
                'fi\nEOF\nchmod +x "$3/bin/python"\n'
            )
            fake_python.chmod(0o755)
            sudo = root / "sudo"
            sudo.write_text('#!/bin/sh\nprintf "sudo\\n" >> "$MARKER"\n')
            sudo.chmod(0o755)
            env = {**os.environ, "PATH": directory + ":" + os.environ["PATH"],
                   "MARKER": str(marker), "ANSIBLE_VENV": str(venv)}
            result = subprocess.run(
                ["bash", "-c", 'source "$1"; main; main', "bash", str(SCRIPT)],
                env=env, capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr.decode())
            self.assertEqual(marker.read_text().splitlines(), ["venv", "pip"])
            self.assertTrue((venv / "bin/ansible-playbook").is_file())


if __name__ == "__main__":
    unittest.main()
