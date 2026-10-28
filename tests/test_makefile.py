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
            (project / "scripts/setup.sh").write_text(
                'printf "installer: %s\\n" "$*" >> "$LOG"\n'
            )
            (project / "scripts/apply-dotfiles.sh").write_text(
                'printf "links: %s\\n" "$*" >> "$LOG"\n'
            )
            (project / "scripts/cachyos.py").write_text(
                'import os, sys\n'
                'with open(os.environ["LOG"], "a") as log:\n'
                '    log.write("planner: " + " ".join(sys.argv[1:]) + "\\n")\n'
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

    def test_setup_dispatches_installer_not_personal_preferences(self):
        result, calls = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["installer: "])

    def test_setup_has_no_feature_argument_variable(self):
        self.assertNotIn("CACHYOS_ARGS", (ROOT / "Makefile").read_text())

    def test_cachyos_preview_uses_the_same_argument_free_defaults(self):
        result, calls = self.run_setup(target="cachyos-plan")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["planner: plan"])

    def test_failed_checks_prevent_configuration_changes(self):
        result, calls = self.run_setup(target="local", check_status=1)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, ["checked"])

    def test_local_keeps_the_same_configuration_only_workflow(self):
        result, calls = self.run_setup(target="local")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["checked", "links: niri fuzzel waybar"])


if __name__ == "__main__":
    unittest.main()
