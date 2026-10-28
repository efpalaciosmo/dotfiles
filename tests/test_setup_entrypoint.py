"""Run the shell entry point with fake OS metadata and harmless command stubs."""

import os
import pty
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipIf(os.geteuid() == 0, "normal-user orchestration is intentionally refused as root")
class SetupEntrypointTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        (self.root / "scripts").mkdir()
        release = self.root / "os-release"
        release.write_text("ID=cachyos\n")
        self.release = release
        script = (ROOT / "scripts/setup.sh").read_text()
        script = script.replace("source /etc/os-release", f'source "{release}"')
        script = script.replace("/run/archiso", str(self.root / "not-live"))
        script = script.replace("/run/miso", str(self.root / "not-live-either"))
        self.script = self.root / "scripts/setup.sh"
        self.script.write_text(script)
        self.log = self.root / "calls"
        self.environment = {**os.environ, "PATH": str(self.bin), "LOG": str(self.log), "STUBBIN": str(self.bin),
                            "XDG_STATE_HOME": str(self.root / "state")}
        for name in ("dirname", "cp", "chmod", "mkdir", "mktemp", "uname"):
            (self.bin / name).symlink_to(shutil.which(name))
        self.stub("systemd-detect-virt", "exit 1\n")
        self.stub("make", 'printf "make: %s\\n" "$*" >> "$LOG"\n')
        self.stub("sudo", 'printf "sudo: %s\\n" "$*" >> "$LOG"\nexit 99\n')

    def stub(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + body)
        path.chmod(0o755)
        return path

    def run_entrypoint(self, *arguments, tty=False):
        if tty:
            master, slave = pty.openpty()
            try:
                os.write(master, b"INSTALL\n")
                result = subprocess.run(["/bin/bash", str(self.script), *arguments], env=self.environment,
                                        stdin=slave, text=True, capture_output=True, timeout=15)
            finally:
                os.close(master)
                os.close(slave)
        else:
            result = subprocess.run(["/bin/bash", str(self.script), *arguments], env=self.environment,
                                    input="", text=True, capture_output=True, timeout=15)
        calls = self.log.read_text().splitlines() if self.log.exists() else []
        return result, calls

    def test_cachyos_runs_checks_then_installer_then_installed_validators(self):
        self.stub("python3", 'printf "python: %s\\n" "$*" >> "$LOG"\n')
        result, calls = self.run_entrypoint()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(calls), 3)
        self.assertTrue(calls[0].endswith(" check"))
        self.assertTrue(calls[1].endswith("cachyos.py setup"))
        self.assertTrue(calls[2].endswith(" check"))
        self.assertFalse(any("local" in call or "sudo" in call for call in calls))

    def test_entrypoint_refuses_feature_arguments_before_any_changes(self):
        result, calls = self.run_entrypoint("--without", "tailscale")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no arguments", result.stderr)
        self.assertEqual(calls, [])

    def test_failed_install_stops_without_linking_personal_dotfiles(self):
        self.stub("python3", 'printf "python: %s\\n" "$*" >> "$LOG"\nexit 23\n')
        result, calls = self.run_entrypoint()
        self.assertEqual(result.returncode, 23)
        self.assertEqual(len(calls), 2)
        self.assertFalse(any("local" in call or "dotfiles" in call for call in calls))

    def test_non_cachyos_retains_configuration_only_setup(self):
        self.release.write_text("ID=fedora\n")
        result, calls = self.run_entrypoint()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(calls), 1)
        self.assertTrue(calls[0].endswith(" local"))

    def test_missing_python_cannot_trigger_noninteractive_upgrade(self):
        result, calls = self.run_entrypoint()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("interactive", result.stderr)
        self.assertEqual(calls, [])

    def bootstrap_stubs(self, policy="Required DatabaseOptional"):
        self.stub("pacman", 'printf "pacman: %s\\n" "$*" >> "$LOG"\n')
        self.stub("systemctl", "exit 0\n")
        self.stub("pacman-conf", f'''case "$*" in
  --repo-list) printf 'cachyos\\ncore\\n' ;;
  *) printf '%s\\n' '{policy}' ;;
esac
''')
        template = self.root / "python-template"
        template.write_text('#!/bin/sh\nprintf "python: %s\\n" "$*" >> "$LOG"\n')
        self.environment["PYTHON_TEMPLATE"] = str(template)
        self.stub("sudo", '''printf "sudo: %s\\n" "$*" >> "$LOG"
cp "$PYTHON_TEMPLATE" "$STUBBIN/python3"
chmod +x "$STUBBIN/python3"
''')

    def test_python_bootstrap_uses_signed_full_upgrade_not_partial_sync(self):
        self.bootstrap_stubs()
        result, calls = self.run_entrypoint(tty=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("sudo: pacman -Syu --needed python", calls)
        self.assertFalse(any("-Sy " in call or "--noconfirm" in call for call in calls))
        self.assertEqual(sum(call.startswith("make:") for call in calls), 2)
        self.assertTrue(any("cachyos.py setup" in call for call in calls))
        self.assertTrue(list(self.root.glob("state/cachyos-desktop/bootstrap-before-*.txt")))

    def test_python_bootstrap_refuses_weakened_signatures(self):
        self.bootstrap_stubs("Optional TrustAll")
        result, calls = self.run_entrypoint(tty=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("signature", result.stderr)
        self.assertFalse(any(call.startswith("sudo:") for call in calls))


if __name__ == "__main__":
    unittest.main()
