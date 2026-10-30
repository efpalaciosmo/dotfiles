"""Run the shell entry point with fake OS metadata and harmless command stubs."""

import os
import pty
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACMAN_CONF = shutil.which("pacman-conf")


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

    def test_non_cachyos_refuses_without_installing_or_linking(self):
        self.release.write_text("ID=fedora\n")
        result, calls = self.run_entrypoint()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("only installed CachyOS", result.stderr)
        self.assertEqual(calls, [])

    def test_missing_python_cannot_trigger_noninteractive_upgrade(self):
        result, calls = self.run_entrypoint()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("interactive", result.stderr)
        self.assertEqual(calls, [])

    def bootstrap_stubs(self, policy="Required DatabaseOptional", repo_policy=None, repo_status=0):
        self.stub("pacman", 'printf "pacman: %s\\n" "$*" >> "$LOG"\n')
        self.stub("systemctl", "exit 0\n")
        self.stub("pacman-conf", f'''case "$*" in
  --repo-list) printf 'cachyos-znver4\\ncore\\n' ;;
  --repo*) printf '%s\\n' '{policy if repo_policy is None else repo_policy}'; exit {repo_status} ;;
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

    def test_python_bootstrap_accepts_inherited_multiline_signature_policy(self):
        policy = "PackageRequired\nPackageTrustedOnly\nDatabaseOptional\nDatabaseTrustedOnly"
        self.bootstrap_stubs(policy, repo_policy="")
        result, calls = self.run_entrypoint(tty=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("sudo: pacman -Syu --needed python", calls)

    def test_python_bootstrap_rejects_explicit_unsafe_repository_policy(self):
        self.bootstrap_stubs(repo_policy="PackageRequired PackageTrustAll")
        result, calls = self.run_entrypoint(tty=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("signature", result.stderr)
        self.assertFalse(any(call.startswith("sudo:") for call in calls))

    def test_python_bootstrap_does_not_inherit_failed_repository_query(self):
        self.bootstrap_stubs(repo_policy="", repo_status=2)
        result, calls = self.run_entrypoint(tty=True)
        self.assertEqual(result.returncode, 2)
        self.assertFalse(any(call.startswith("sudo:") for call in calls))

    def test_python_bootstrap_rejects_empty_global_signature_policy(self):
        self.bootstrap_stubs(policy="", repo_policy="")
        result, calls = self.run_entrypoint(tty=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("signature", result.stderr)
        self.assertFalse(any(call.startswith("sudo:") for call in calls))

    def native_bootstrap_stubs(self, repo_policy=None):
        self.bootstrap_stubs()
        config = self.root / "pacman.conf"
        config.write_text("[options]\nArchitecture = x86_64\nSigLevel = Required DatabaseOptional\n"
                          "[cachyos-znver4]\n"
                          + (f"SigLevel = {repo_policy}\n" if repo_policy else "")
                          + "Server = https://mirror.example.invalid/$repo/$arch\n"
                          "[core]\nServer = https://mirror.example.invalid/$repo/$arch\n")
        self.stub("pacman-conf", f'exec "{PACMAN_CONF}" --config "{config}" "$@"\n')

    @unittest.skipUnless(PACMAN_CONF, "requires native pacman-conf")
    def test_python_bootstrap_with_real_parser_accepts_inherited_policy(self):
        self.native_bootstrap_stubs()
        result, calls = self.run_entrypoint(tty=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("sudo: pacman -Syu --needed python", calls)

    @unittest.skipUnless(PACMAN_CONF, "requires native pacman-conf")
    def test_python_bootstrap_with_real_parser_rejects_unsafe_override(self):
        self.native_bootstrap_stubs(repo_policy="TrustAll")
        result, calls = self.run_entrypoint(tty=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("cachyos-znver4", result.stderr)
        self.assertFalse(any(call.startswith("sudo:") for call in calls))


if __name__ == "__main__":
    unittest.main()
