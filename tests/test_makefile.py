"""Exercise configuration-only entry points without changing the host."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PACKAGES = "git shell-container starship vi ghostty niri waybar mako fuzzel desktop gnome"


class MakefileTests(unittest.TestCase):
    def run_make(self, target=None, check_status=0, parallel=False, packages=None):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            shutil.copyfile(ROOT / "Makefile", project / "Makefile")
            (project / "packages/fuzzel/.config/fuzzel/scripts").mkdir(parents=True)
            (project / "scripts").mkdir()
            (project / "scripts/apply-dotfiles.sh").write_text(
                'printf "links: %s\\n" "$*" >> "$LOG"\n'
            )
            doctor = project / "scripts/doctor.sh"
            doctor.write_text('#!/bin/sh\nprintf "doctor: %s\\n" "$*" >> "$LOG"\n')
            doctor.chmod(0o755)
            (project / "checks.mk").write_text(
                'check:\n\t@echo checked >> "$(LOG)"\n'
                f'\t@exit {check_status}\n'
            )
            log = project / "calls"
            result = subprocess.run(
                ["make", "--no-print-directory", "-f", "Makefile", "-f", "checks.mk",
                  *([target] if target else []), *(["-j8"] if parallel else []),
                  *([f"PACKAGES={packages}"] if packages is not None else [])], cwd=project,
                env={**os.environ, "LOG": str(log)}, text=True, capture_output=True,
            )
            return result, log.read_text().splitlines() if log.exists() else []

    def test_plain_make_configures_both_desktops_once_even_in_parallel(self):
        for parallel in (False, True):
            with self.subTest(parallel=parallel):
                result, calls = self.run_make(parallel=parallel)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(calls, [f"links: {DEFAULT_PACKAGES}"])

    def test_default_target_and_help_expose_only_distinct_operations(self):
        result, calls = self.run_make(target="dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [f"links: {DEFAULT_PACKAGES}"])
        result, calls = self.run_make(target="help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [])
        targets = {line.split()[0] for line in result.stdout.splitlines()}
        self.assertEqual(targets, {"dotfiles", "check", "doctor", "help"})

    def test_duplicate_and_software_installation_targets_are_removed(self):
        for target in ("all", "local", "stow", "gnome", "verify", "setup"):
            with self.subTest(target=target):
                result, calls = self.run_make(target=target)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(calls, [])

    def test_checks_never_apply_configuration_even_on_failure(self):
        result, calls = self.run_make(target="check", check_status=1)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, ["checked"])

    def test_doctor_checks_both_desktops_without_applying_configuration(self):
        result, calls = self.run_make(target="doctor")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [f"doctor: {DEFAULT_PACKAGES}"])

    def test_package_override_still_supports_targeted_linking(self):
        result, calls = self.run_make(packages="niri gnome desktop")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["links: niri gnome desktop"])


if __name__ == "__main__":
    unittest.main()
