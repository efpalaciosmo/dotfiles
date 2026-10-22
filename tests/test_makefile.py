"""Exercise setup ordering and package selection without changing the host."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class MakefileTests(unittest.TestCase):
    def run_setup(self, target="setup", check_status=0):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            shutil.copyfile(ROOT / "Makefile", project / "Makefile")
            (project / "packages/fuzzel/.config/fuzzel/scripts").mkdir(parents=True)
            (project / "scripts").mkdir()
            (project / "scripts/apply-dotfiles.sh").write_text(
                'printf "links: %s\\n" "$*" >> "$LOG"\n'
            )
            (project / "checks.mk").write_text(
                'check:\n\t@echo checked >> "$(LOG)"\n'
                f'\t@exit {check_status}\n'
            )
            log = project / "calls"
            result = subprocess.run(
                ["make", "--no-print-directory", "-f", "Makefile", "-f", "checks.mk",
                 target, "PACKAGES=niri fuzzel waybar"], cwd=project,
                env={**os.environ, "LOG": str(log)}, text=True, capture_output=True,
            )
            return result, log.read_text().splitlines() if log.exists() else []

    def test_setup_checks_before_linking_selected_configs(self):
        result, calls = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["checked", "links: niri fuzzel waybar"])

    def test_failed_checks_prevent_configuration_changes(self):
        result, calls = self.run_setup(check_status=1)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, ["checked"])

    def test_local_keeps_the_same_configuration_only_workflow(self):
        result, calls = self.run_setup(target="local")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["checked", "links: niri fuzzel waybar"])


if __name__ == "__main__":
    unittest.main()
