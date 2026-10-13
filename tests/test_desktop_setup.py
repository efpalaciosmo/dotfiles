"""Exercise hardware setup decisions without mutating the host."""
import contextlib
import importlib.util
import io
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts' / (name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


network = load('libvirt-network')
auth = load('libvirt-check')
NAT = '<network><name>default</name><forward mode="nat"/><bridge name="virbr0"/><ip address="192.168.122.1" netmask="255.255.255.0"/></network>'


class NetworkTests(unittest.TestCase):
    def test_route_conflicts_are_rejected_but_own_bridge_is_allowed(self):
        root = ET.fromstring(NAT)
        network.check_conflicts(root, [{'dst': 'default'}, {'dst': '192.168.122.0/24', 'dev': 'virbr0'}])
        with self.assertRaisesRegex(RuntimeError, 'overlaps route'):
            network.check_conflicts(root, [{'dst': '192.168.0.0/16', 'dev': 'tailscale0'}])

    def configure(self, present=True, active=True, auto=True, routes='[]', firewall_failure=False):
        calls = []
        def virsh(*args, **kwargs):
            calls.append(args)
            if args[0] == 'net-dumpxml':
                return SimpleNamespace(stdout=NAT)
            if args[0] == 'net-list':
                value = present if '--all' in args else active
                if '--autostart' in args:
                    value = auto
                return SimpleNamespace(stdout='default\n' if value else '')
            if args[0] == 'net-start' and firewall_failure:
                raise RuntimeError('firewall failed')
            return SimpleNamespace(stdout='')
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'default.xml'
            source.write_text(NAT)
            with patch.object(network, 'PACKAGED', source), patch.object(network, 'virsh', side_effect=virsh), \
                 patch.object(network.subprocess, 'run', return_value=SimpleNamespace(stdout=routes)), \
                 contextlib.redirect_stdout(io.StringIO()) as output:
                try:
                    network.configure()
                    return calls, output.getvalue(), None
                except RuntimeError as error:
                    return calls, output.getvalue(), str(error)

    def test_repeat_network_setup_has_no_mutations(self):
        calls, output, error = self.configure()
        self.assertIsNone(error)
        self.assertNotIn('CHANGED', output)
        self.assertFalse(any(c[0] in ('net-define', 'net-start', 'net-autostart') for c in calls))

    def test_new_default_uses_packaged_definition_and_starts_once(self):
        calls, output, error = self.configure(present=False, active=False, auto=False)
        self.assertIsNone(error)
        self.assertIn('CHANGED', output)
        self.assertEqual([c[0] for c in calls if c[0] in ('net-define', 'net-start', 'net-autostart')],
                         ['net-define', 'net-start', 'net-autostart'])

    def test_conflict_prevents_changes_and_firewall_failure_is_reported(self):
        calls, _, error = self.configure(active=False, routes='[{"dst":"192.168.122.0/24","dev":"eth0"}]')
        self.assertIn('overlaps', error)
        self.assertFalse(any(c[0] == 'net-start' for c in calls))
        calls, _, error = self.configure(active=False, auto=False, firewall_failure=True)
        self.assertIn('firewall failed', error)
        self.assertFalse(any(c[0] == 'net-autostart' for c in calls))


class AuthorizationTests(unittest.TestCase):
    def test_pending_membership_never_attempts_authentication(self):
        import pwd
        username = pwd.getpwuid(os.getuid()).pw_name
        group = SimpleNamespace(gr_gid=12345, gr_mem=[username])
        with patch.object(auth.grp, 'getgrnam', return_value=group), \
             patch.object(auth.os, 'getgroups', return_value=[]), patch.object(auth.os, 'getgid', return_value=1000), \
             patch.object(auth.subprocess, 'run') as run, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(auth.check(), 2)
            run.assert_not_called()

    def test_auth_failure_never_attempts_rw_connection(self):
        group = SimpleNamespace(gr_gid=os.getgid(), gr_mem=[])
        with patch.object(auth.grp, 'getgrnam', return_value=group), \
             patch.object(auth.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, 'pkcheck')) as run, \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(auth.check(), 1)
            self.assertEqual(run.call_count, 1)
            self.assertNotIn('--allow-user-interaction', run.call_args.args[0])

    def test_success_uses_bounded_rw_queries_without_prompt(self):
        group = SimpleNamespace(gr_gid=os.getgid(), gr_mem=[])
        with patch.object(auth.grp, 'getgrnam', return_value=group), \
             patch.object(auth.subprocess, 'run') as run, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(auth.check(), 0)
            self.assertEqual(run.call_count, 4)
            for call in run.call_args_list[1:]:
                self.assertNotIn('--readonly', call.args[0])
                self.assertEqual(call.kwargs['timeout'], 15)


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
