"""Exercise configuration-only entry points without changing the host."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class MakefileTests(unittest.TestCase):
    def run_make(self, target=None, check_status=0, parallel=False):
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
                  *([target] if target else []), *(["-j8"] if parallel else []),
                  "PACKAGES=niri fuzzel waybar"], cwd=project,
                env={**os.environ, "LOG": str(log)}, text=True, capture_output=True,
            )
            return result, log.read_text().splitlines() if log.exists() else []

    def test_plain_make_only_links_even_in_parallel(self):
        for parallel in (False, True):
            with self.subTest(parallel=parallel):
                result, calls = self.run_make(parallel=parallel)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(calls, ["links: niri fuzzel waybar"])

    def test_dotfiles_only_links_and_help_is_read_only(self):
        result, calls = self.run_make(target="dotfiles")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["links: niri fuzzel waybar"])
        result, calls = self.run_make(target="help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [])

    def test_software_installation_target_is_unavailable(self):
        result, calls = self.run_make(target="setup")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, [])

    def test_failed_checks_prevent_configuration_changes(self):
        result, calls = self.run_make(target="local", check_status=1)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, ["checked"])

    def test_local_keeps_the_same_configuration_only_workflow(self):
        result, calls = self.run_make(target="local")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["checked", "links: niri fuzzel waybar"])


if __name__ == "__main__":
    unittest.main()
