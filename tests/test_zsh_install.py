"""scripts/install-zsh.sh against throw-away local repositories (no network, no real HOME)."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/install-zsh.sh"
GIT = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.com",
       "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@example.com"}


def git(directory, *args):
    return subprocess.run(["git", "-C", str(directory), *args], check=True, text=True,
                          capture_output=True, env={**os.environ, **GIT}).stdout.strip()


def make_repo(path, filename, content="x"):
    path.mkdir(parents=True)
    git(path, "init", "--quiet")
    (path / filename).write_text(content)
    git(path, "add", "-A")
    git(path, "commit", "--quiet", "-m", "init")
    return git(path, "rev-parse", "HEAD")


@unittest.skipUnless(shutil.which("git"), "git unavailable")
class InstallZshTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        root = Path(directory.name)
        self.home = root / "home"
        self.home.mkdir()
        self.omz = make_repo(root / "omz", "oh-my-zsh.sh")
        self.auto = make_repo(root / "auto", "zsh-autosuggestions.zsh")
        self.high = make_repo(root / "high", "zsh-syntax-highlighting.zsh")
        self.root = root
        self.env = {**os.environ, "HOME": str(self.home),
                    "DOTFILES_OMZ_URL": str(root / "omz"), "DOTFILES_OMZ_SHA": self.omz,
                    "DOTFILES_AUTOSUGGESTIONS_URL": str(root / "auto"),
                    "DOTFILES_AUTOSUGGESTIONS_SHA": self.auto,
                    "DOTFILES_HIGHLIGHTING_URL": str(root / "high"),
                    "DOTFILES_HIGHLIGHTING_SHA": self.high}
        for name in ("ZSH", "ZSH_CUSTOM"):
            self.env.pop(name, None)

    def run_script(self, **overrides):
        return subprocess.run(["bash", str(SCRIPT)], env={**self.env, **overrides},
                              text=True, capture_output=True)

    def test_installs_oh_my_zsh_and_both_plugins_at_the_pinned_commits(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        omz = self.home / ".oh-my-zsh"
        self.assertTrue((omz / "oh-my-zsh.sh").is_file())
        self.assertEqual(git(omz, "rev-parse", "HEAD"), self.omz)
        for name, sha in (("zsh-autosuggestions", self.auto), ("zsh-syntax-highlighting", self.high)):
            plugin = omz / "custom/plugins" / name
            self.assertEqual(git(plugin, "rev-parse", "HEAD"), sha)
        self.assertFalse(list(self.home.glob(".oh-my-zsh*.tmp.*")), "temporary clones are cleaned up")

    def test_second_run_changes_nothing(self):
        self.assertEqual(self.run_script().returncode, 0)
        marker = self.home / ".oh-my-zsh/marker"
        marker.write_text("untracked file must survive")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("already at", result.stdout)
        self.assertEqual(marker.read_text(), "untracked file must survive")

    def test_clean_checkout_is_moved_to_a_bumped_commit(self):
        self.assertEqual(self.run_script().returncode, 0)
        (self.root / "omz/next").write_text("2")
        git(self.root / "omz", "add", "-A")
        git(self.root / "omz", "commit", "--quiet", "-m", "next")
        new = git(self.root / "omz", "rev-parse", "HEAD")
        result = self.run_script(DOTFILES_OMZ_SHA=new)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(git(self.home / ".oh-my-zsh", "rev-parse", "HEAD"), new)

    def test_local_changes_are_never_overwritten(self):
        self.assertEqual(self.run_script().returncode, 0)
        edited = self.home / ".oh-my-zsh/oh-my-zsh.sh"
        edited.write_text("my edit")
        (self.root / "omz/next").write_text("2")
        git(self.root / "omz", "add", "-A")
        git(self.root / "omz", "commit", "--quiet", "-m", "next")
        result = self.run_script(DOTFILES_OMZ_SHA=git(self.root / "omz", "rev-parse", "HEAD"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("local changes", result.stderr)
        self.assertEqual(edited.read_text(), "my edit")

    def test_existing_non_git_directory_is_left_alone(self):
        omz = self.home / ".oh-my-zsh"
        omz.mkdir()
        (omz / "mine").write_text("keep")
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((omz / "mine").read_text(), "keep")
        self.assertFalse((omz / "custom").exists())

    def test_failed_download_leaves_no_half_installed_directory(self):
        result = self.run_script(DOTFILES_OMZ_URL=str(self.root / "missing"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not download", result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
