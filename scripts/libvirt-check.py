#!/usr/bin/env python3
"""Check effective libvirt authorization without invoking an authentication agent."""
import grp
import os
import subprocess
import sys
from pathlib import Path


def check():
    try:
        group = grp.getgrnam('libvirt')
    except KeyError:
        print('MISS libvirt group; run make libvirt')
        return 1
    effective = set(os.getgroups()) | {os.getgid()}
    if group.gr_gid not in effective:
        import pwd
        if pwd.getpwuid(os.getuid()).pw_name in group.gr_mem:
            print('PENDING re-login: libvirt membership is assigned but absent from this session; log out fully and back in')
            return 2
        print('MISS libvirt group membership; run make libvirt')
        return 1
    # Include process start time and UID to bind the polkit subject unambiguously.
    start = Path('/proc/self/stat').read_text().rsplit(') ', 1)[1].split()[19]
    subject = f'{os.getpid()},{start},{os.getuid()}'
    try:
        subprocess.run(['pkcheck', '--action-id', 'org.libvirt.unix.manage', '--process', subject],
                       check=True, timeout=10, capture_output=True)
        for query in ('list', 'net-list', 'pool-list'):
            subprocess.run(['virsh', '--connect', 'qemu:///system', query, '--all'],
                           check=True, timeout=15, capture_output=True)
    except (OSError, subprocess.SubprocessError) as error:
        print(f'MISS libvirt noninteractive management access: {error}')
        return 1
    print('OK libvirt management authorized without authentication; bounded read-write connection queries passed')
    return 0


if __name__ == '__main__':
    sys.exit(check())
