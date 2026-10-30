"""Real GNU Stow integration in a disposable HOME, never the user's files."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("stow"), "GNU Stow unavailable")
@unittest.skipIf(os.geteuid() == 0, "dotfiles intentionally refuse root")
class StowTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.repo, self.home = self.root / "repo", self.root / "home"
        self.home.mkdir()
        shutil.copytree(ROOT / "scripts", self.repo / "scripts", ignore=shutil.ignore_patterns("__pycache__"))
        shutil.copytree(ROOT / "packages", self.repo / "packages", ignore=shutil.ignore_patterns("__pycache__"))
        binary = self.root / "bin"
        binary.mkdir()
        for name in ("ghostty", "niri", "fuzzel", "gsettings"):
            path = binary / name
            path.write_text("#!/bin/sh\nexit 0\n")
            path.chmod(0o755)
        self.environment = {**os.environ, "HOME": str(self.home), "PATH": f"{binary}:{os.environ['PATH']}",
                            "XDG_CURRENT_DESKTOP": "niri"}

    def apply(self, *packages):
        return subprocess.run(["bash", str(self.repo / "scripts/apply-dotfiles.sh"), *packages],
                              env=self.environment, text=True, capture_output=True)

    def successful(self, *packages):
        result = self.apply(*packages)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_full_default_selection_links_and_reapplies_without_backups(self):
        packages = (ROOT / "Makefile").read_text().split("PACKAGES :=", 1)[1].splitlines()[0].split()
        self.successful(*packages)
        self.successful(*packages)
        for package in packages:
            source = self.repo / "packages" / package
            for file in source.rglob("*"):
                if not file.is_file() or file.name.lower() == "readme" or file.name.lower().startswith("readme."):
                    continue
                target = self.home / file.relative_to(source)
                self.assertTrue(target.is_symlink(), target)
                self.assertEqual(target.resolve(), file.resolve())
        self.assertFalse(list(self.home.rglob("*.bak*")))

    def test_conflicts_are_backed_up_once_without_overwriting_older_backups(self):
        config = self.home / ".config/ghostty/config"
        config.parent.mkdir(parents=True)
        config.write_text("personal config")
        config.with_name("config.bak").write_text("older backup")
        self.successful("ghostty")
        self.successful("ghostty")
        self.assertEqual(config.with_name("config.bak").read_text(), "older backup")
        self.assertEqual(config.with_name("config.bak.1").read_text(), "personal config")
        self.assertFalse(config.with_name("config.bak.2").exists())

    def test_new_ghostty_config_cannot_shadow_the_managed_theme(self):
        config = self.home / ".config/ghostty/config.ghostty"
        config.parent.mkdir(parents=True)
        config.write_text("theme = different\n")
        self.successful("ghostty")
        self.successful("ghostty")
        self.assertTrue(config.is_symlink())
        self.assertIn("theme = Adwaita Dark Orange", config.read_text())
        self.assertEqual(config.with_name("config.ghostty.bak").read_text(), "theme = different\n")
        self.assertFalse(config.with_name("config.ghostty.bak.1").exists())

    def test_unmanaged_parent_link_does_not_move_external_files(self):
        outside = self.root / "external"
        (outside / "ghostty").mkdir(parents=True)
        config = outside / "ghostty/config"
        config.write_text("external config")
        (self.home / ".config").symlink_to(outside)
        self.successful("ghostty")
        self.assertEqual(config.read_text(), "external config")
        self.assertTrue((self.home / ".config.bak").is_symlink())
        self.assertFalse((self.home / ".config").is_symlink())

    def test_old_folded_managed_directory_is_unfolded_by_stow(self):
        (self.home / ".config").mkdir()
        (self.home / ".config/ghostty").symlink_to(self.repo / "packages/ghostty/.config/ghostty")
        self.successful("ghostty")
        self.assertFalse((self.home / ".config/ghostty").is_symlink())
        self.assertTrue((self.home / ".config/ghostty/config").is_symlink())

    def test_old_absolute_file_link_is_converted_without_a_backup(self):
        target = self.home / ".vimrc"
        target.symlink_to(self.repo / "packages/vi/.vimrc")
        self.successful("vi")
        self.assertFalse(os.readlink(target).startswith("/"))
        self.assertFalse((self.home / ".vimrc.bak").exists())

    def test_file_blocking_a_parent_directory_is_backed_up(self):
        target = self.home / ".config"
        target.write_text("obstructing file")
        self.successful("ghostty")
        self.assertEqual((self.home / ".config.bak").read_text(), "obstructing file")
        self.assertTrue((target / "ghostty/config").is_symlink())

    def test_unknown_package_is_refused_before_any_backups(self):
        config = self.home / ".vimrc"
        config.write_text("personal vim")
        result = self.apply("vi", "../outside")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(config.read_text(), "personal vim")
        self.assertFalse((self.home / ".vimrc.bak").exists())

    def test_generated_python_caches_are_not_linked(self):
        cache = self.repo / "packages/ghostty/.config/ghostty/__pycache__"
        cache.mkdir()
        (cache / "generated.pyc").write_bytes(b"generated artifact")
        self.successful("ghostty")
        self.assertFalse((self.home / ".config/ghostty/__pycache__").exists())

    def test_only_kitty_links_owned_by_this_clone_are_retired(self):
        target = self.home / ".config/kitty"
        target.parent.mkdir()
        target.symlink_to(self.repo / "packages/kitty/.config/kitty")
        self.successful("ghostty")
        self.assertFalse(target.is_symlink())
        target.mkdir()
        file = target / "kitty.conf"
        file.symlink_to(self.repo / "packages/kitty/.config/kitty/kitty.conf")
        self.successful("ghostty")
        self.assertFalse(file.is_symlink())
        file.write_text("independent config")
        self.successful("ghostty")
        self.assertEqual(file.read_text(), "independent config")
