"""Validate dotfiles before changing user configuration."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ConfigValidationTests(unittest.TestCase):
    def test_invalid_config_prevents_backups_and_stow(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            commands = home / 'bin'
            commands.mkdir()
            for name, body in {'niri': 'exit 0', 'fuzzel': 'exit 13', 'stow': 'touch "$HOME/stow-called"'}.items():
                path = commands / name
                path.write_text('#!/bin/sh\n' + body + '\n')
                path.chmod(0o755)
            config = home / '.config/niri/config.kdl'
            config.parent.mkdir(parents=True)
            config.write_text('existing configuration')
            env = {**os.environ, 'HOME': directory, 'PATH': str(commands) + ':' + os.environ['PATH']}
            result = subprocess.run(['bash', str(ROOT / 'scripts/apply-dotfiles.sh'), 'niri', 'fuzzel'], env=env, capture_output=True)
            self.assertEqual(result.returncode, 13)
            self.assertEqual(config.read_text(), 'existing configuration')
            self.assertFalse(config.with_suffix('.kdl.bak').exists())
            self.assertFalse((home / 'stow-called').exists())


if __name__ == '__main__':
    unittest.main()
