"""Authorization, account preparation and next-boot NAT, without host changes."""

import importlib.util
import ipaddress
import json
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


installer = load("vm_installer", "scripts/cachyos.py")
network = load("vm_network", "cachyos/config/libvirt-network.py")


class AuthorizationTests(unittest.TestCase):
    def plan(self, user="tester"):
        args = installer.parser().parse_args(["--profile", "custom", "--include", "virtualization-core", "--initial-user", user])
        return installer.build_plan(args, {"architecture": "x86_64"})

    def test_single_account_policy_is_rendered_without_shell_or_js_injection(self):
        user = 'quoted"account\\name'
        result = self.plan(user)
        rule = result["files"]["/etc/polkit-1/rules.d/00-cachyos-libvirt-admin.rules"]["content"]
        self.assertIn("subject.user == " + json.dumps(user), rule)
        self.assertNotIn("@USER@", rule)
        self.assertIn("subject.local && subject.active", rule)
        self.assertIn('subject.isInGroup("libvirt")', rule)
        self.assertIn("cachyos-libvirt-network.service", result["system_units"])

    @unittest.skipUnless(shutil.which("node"), "optional JavaScript rule interpreter unavailable")
    def test_actual_javascript_rule_denies_remote_inactive_and_other_accounts(self):
        rule = self.plan()["files"]["/etc/polkit-1/rules.d/00-cachyos-libvirt-admin.rules"]["content"]
        javascript = '''let callback;
const polkit = {Result:{YES:"yes", AUTH_ADMIN:"admin"}, addRule: f => callback=f};
''' + rule + '''
const subject = {user:"tester", local:true, active:true, isInGroup: g => g === "libvirt"};
const action = {id:"org.libvirt.unix.manage"};
console.log(JSON.stringify([
  callback(action, subject),
  callback(action, {...subject, user:"someone-else"}),
  callback(action, {...subject, local:false}),
  callback(action, {...subject, active:false}),
  callback(action, {...subject, isInGroup: () => false}),
  callback({id:"unrelated.action"}, subject)
]));
'''
        result = subprocess.run(["node", "-e", javascript], capture_output=True, text=True, check=True)
        self.assertEqual(json.loads(result.stdout), ["yes", "admin", "admin", "admin", "admin", None])

    def test_target_group_membership_is_allowed_but_other_members_need_review(self):
        result = self.plan()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "etc").mkdir()
            (root / "etc/group").write_text("libvirt:x:123:tester\n")
            self.assertEqual(installer.conflicts(result, root, lambda unit: False), [])
            (root / "etc/group").write_text("libvirt:x:123:tester,other\n")
            self.assertTrue(any("other" in item for item in installer.conflicts(result, root, lambda unit: False)))

    def test_usermod_appends_without_replacing_existing_groups(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(installer.grp, "getgrnam"), \
                patch.object(installer, "run", side_effect=["wheel audio", "wheel audio libvirt"]), \
                patch.object(installer, "mutate") as mutate:
            installer.apply_preparation({"files": {}, "generate_locale": False, "libvirt_user": "tester"}, Path(directory))
        mutate.assert_called_once_with("usermod", "--append", "--groups", "libvirt", "--", "tester")

    def test_reapply_does_not_duplicate_group_operations(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(installer.grp, "getgrnam"), \
                patch.object(installer, "run", return_value="wheel libvirt"), patch.object(installer, "mutate") as mutate:
            installer.apply_preparation({"files": {}, "generate_locale": False, "libvirt_user": "tester"}, Path(directory))
        mutate.assert_not_called()


class NetworkTests(unittest.TestCase):
    def exercise(self, existing=True, active=False, routes=(), xml=None, links=()):
        calls, definitions = [], []
        xml = xml or network.network_definition(ipaddress.ip_network("192.168.122.0/24"))

        def virsh(*args):
            calls.append(args)
            if args == ("net-list", "--all", "--name"):
                return "default" if existing else ""
            if args == ("net-dumpxml", "default"):
                return definitions[-1] if definitions else xml
            if args == ("net-list", "--name"):
                return "default" if active else ""
            if args[0] == "net-define":
                definitions.append(Path(args[1]).read_text())
            return ""

        def run(*args):
            return json.dumps(links if args[-2:] == ("link", "show") else routes)

        with patch.object(network, "virsh", side_effect=virsh), patch.object(network, "run", side_effect=run), redirect_stdout(StringIO()):
            network.main()
        return calls, definitions

    def test_packaged_default_nat_is_started_without_redefinition(self):
        calls, definitions = self.exercise()
        self.assertEqual(definitions, [])
        self.assertIn(("net-start", "default"), calls)
        self.assertIn(("net-autostart", "default"), calls)

    def test_active_nat_is_not_restarted_and_its_own_route_is_ignored(self):
        calls, definitions = self.exercise(active=True, routes=[{"dst": "192.168.122.0/24", "dev": "virbr0"}])
        self.assertEqual(definitions, [])
        self.assertNotIn(("net-start", "default"), calls)

    def test_missing_default_chooses_nonoverlapping_subnet(self):
        calls, definitions = self.exercise(existing=False, routes=[{"dst": "192.168.122.0/24", "dev": "eth0"}])
        self.assertEqual(len(definitions), 1)
        ip = ET.fromstring(definitions[0]).find("ip")
        self.assertEqual(ip.get("address"), "192.168.123.1")
        self.assertEqual(ip.find("dhcp/range").get("end"), "192.168.123.254")

    def test_existing_non_nat_network_is_preserved_and_refused(self):
        xml = network.network_definition(ipaddress.ip_network("192.168.122.0/24")).replace('mode="nat"', 'mode="route"')
        with self.assertRaisesRegex(RuntimeError, "not NAT"):
            self.exercise(xml=xml)

    def test_existing_nat_with_conflicting_host_route_is_not_rewritten(self):
        with self.assertRaisesRegex(RuntimeError, "overlaps"):
            self.exercise(routes=[{"dst": "192.168.122.0/24", "dev": "wlan0"}])

    def test_unowned_existing_bridge_is_not_taken_over(self):
        with self.assertRaisesRegex(RuntimeError, "virbr0 already exists"):
            self.exercise(existing=False, links=[{"ifname": "virbr0"}])

    def test_no_free_subnet_is_not_solved_by_disabling_firewall(self):
        with self.assertRaisesRegex(RuntimeError, "No unused"):
            self.exercise(existing=False, routes=[{"dst": "192.168.0.0/16", "dev": "vpn0"}])
