#!/usr/bin/env python3
"""Start/autostart only the packaged default NAT network; preserve other definitions."""
import ipaddress
import json
import os
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


PACKAGED = Path('/usr/share/libvirt/networks/default.xml')


def virsh(*args, check=True):
    p = subprocess.run(['virsh', '--connect', 'qemu:///system', *args], capture_output=True,
                       text=True, timeout=20, env={**os.environ, 'LC_ALL': 'C'})
    if check and p.returncode:
        raise RuntimeError(p.stderr.strip() or p.stdout.strip())
    return p


def subnet(root):
    node = root.find('ip')
    if node is None or not node.get('address'):
        raise RuntimeError('default network has no IPv4 address; review existing definition')
    mask = node.get('prefix') or node.get('netmask')
    if not mask:
        raise RuntimeError('default network has no subnet mask')
    return ipaddress.ip_network(f"{node.get('address')}/{mask}", strict=False)


def check_conflicts(root, routes):
    network = subnet(root)
    bridge = root.find('bridge')
    bridge_name = bridge.get('name') if bridge is not None else None
    for route in routes:
        dest = route.get('dst', 'default')
        if dest == 'default' or (bridge_name and route.get('dev') == bridge_name):
            continue
        if network.overlaps(ipaddress.ip_network(dest, strict=False)):
            raise RuntimeError(f'default NAT {network} overlaps route {dest} on {route.get("dev")}; resolve subnet conflict manually')


def configure():
    names = virsh('net-list', '--all', '--name').stdout.splitlines()
    exists = 'default' in names
    root = ET.fromstring(virsh('net-dumpxml', 'default').stdout) if exists else ET.parse(PACKAGED).getroot()
    if root.find('name') is None or root.find('name').text != 'default':
        raise RuntimeError('packaged network is not named default')
    forward = root.find('forward')
    if forward is None or forward.get('mode') != 'nat':
        raise RuntimeError('existing default network is not NAT; preserved without modification')
    routes = subprocess.run(['ip', '-j', '-4', 'route', 'show', 'table', 'all'], text=True,
                            capture_output=True, check=True, timeout=10)
    check_conflicts(root, json.loads(routes.stdout))
    for name in names:
        if name and name != 'default':
            other = ET.fromstring(virsh('net-dumpxml', name).stdout)
            if other.find('ip') is not None and subnet(root).overlaps(subnet(other)):
                raise RuntimeError(f'default NAT overlaps existing libvirt network {name}; review definitions manually')
    changed = False
    if not exists:
        virsh('net-define', str(PACKAGED))
        changed = True
    active = virsh('net-list', '--name').stdout.splitlines()
    if 'default' not in active:
        virsh('net-start', 'default')  # Report firewall/start errors; never rewrite firewall.
        changed = True
    autostart = virsh('net-list', '--all', '--autostart', '--name').stdout.splitlines()
    if 'default' not in autostart:
        virsh('net-autostart', 'default')
        changed = True
    print('CHANGED default NAT started/autostarted' if changed else 'OK default NAT already active and autostarted')


if __name__ == '__main__':
    try:
        configure()
    except (OSError, ValueError, ET.ParseError, RuntimeError, subprocess.SubprocessError) as error:
        sys.exit(f'libvirt default NAT: {error}; definitions and unrelated firewall settings were preserved')
