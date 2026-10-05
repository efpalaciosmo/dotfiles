"""The Make entry points must handle Ansible privilege escalation explicitly."""

import unittest
from pathlib import Path


MAKEFILE = (Path(__file__).resolve().parents[1] / "Makefile").read_text()


class MakefileTests(unittest.TestCase):
    def test_privileged_targets_ask_ansible_for_become_password(self):
        for target in ("setup", "packages", "services", "libvirt"):
            recipe = MAKEFILE.split(f"\n{target}:", 1)[1].split("\n\n", 1)[0]
            self.assertIn("ansible-playbook --ask-become-pass", recipe)
            self.assertNotIn("sudo -v", recipe)

    def test_unprivileged_targets_do_not_request_password(self):
        for target in ("local", "fonts", "dotfiles", "flatpak"):
            recipe = MAKEFILE.split(f"\n{target}:", 1)[1].split("\n\n", 1)[0]
            self.assertNotIn("--ask-become-pass", recipe)


if __name__ == "__main__":
    unittest.main()
