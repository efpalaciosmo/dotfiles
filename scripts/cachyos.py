#!/usr/bin/env python3
"""Conservative CachyOS post-install planner. No mutations without `apply`."""

import argparse
import configparser
import datetime
import hashlib
import json
import os
import platform
import pwd
import re
import shutil
import subprocess
import sys
import textwrap
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "cachyos"
MANIFEST = json.loads((DATA / "modules.json").read_text())
FLATHUB_SHA256 = "3371dd250e61d9e1633630073fefda153cd4426f72f4afa0c3373ae2e8fea03a"
STATE = Path("/var/lib/cachyos-desktop")
DEFAULT_PROFILE = "workstation"
MONOLITHIC = [f"libvirtd{suffix}" for suffix in (
    ".service", ".socket", "-ro.socket", "-admin.socket", "-tcp.socket", "-tls.socket"
)]
REMOTE_LIBVIRT = ["virtproxyd-tcp.socket", "virtproxyd-tls.socket"]
POWER = ["tuned.service", "tuned-ppd.service", "power-profiles-daemon.service",
         "tlp.service", "auto-cpufreq.service", "system76-power.service"]
FIREWALL = ["firewalld.service", "ufw.service", "nftables.service",
            "iptables.service", "ip6tables.service"]


class Refusal(RuntimeError):
    """A condition requiring deliberate operator review, not an automatic fix."""


def run(*args, required=True):
    try:
        result = subprocess.run(args, text=True, capture_output=True,
                                stdin=subprocess.DEVNULL,
                                env={**os.environ, "LC_ALL": "C"}, timeout=120)
    except (OSError, subprocess.TimeoutExpired) as exc:
        if required:
            raise Refusal(f"Cannot run {args[0]}: {exc}") from exc
        return ""
    if result.returncode and required:
        raise Refusal(f"{' '.join(args)}: {result.stderr.strip() or result.stdout.strip()}")
    return result.stdout.strip() if result.returncode == 0 else ""


def mutate(*args):
    # Inherit the terminal for pacman's transaction and replacement prompts.
    print("+ " + " ".join(args), flush=True)
    if subprocess.run(args, check=False).returncode:
        raise Refusal(f"Command failed: {' '.join(args)}; inspect the saved run inventory.")


def read(path):
    try:
        return Path(path).read_text()
    except FileNotFoundError:
        return ""


def digest(content):
    return hashlib.sha256(content).hexdigest()


def resolve(profile, include, exclude):
    requested = list(dict.fromkeys(MANIFEST["profiles"][profile] + include))
    unknown = (set(requested) | set(exclude)) - MANIFEST["modules"].keys()
    if unknown:
        raise Refusal("Unknown modules: " + ", ".join(sorted(unknown)))
    if set(exclude) & {"base", "recovery"}:
        raise Refusal("base and recovery cannot be omitted")
    requested = [name for name in requested if name not in exclude]
    resolved = []

    def visit(name, visiting):
        if name in exclude:
            raise Refusal(f"A selected module requires explicitly omitted module {name}")
        if name in visiting:
            raise Refusal(f"Dependency cycle at {name}")
        if name not in resolved:
            for dependency in MANIFEST["modules"][name]["dependencies"]:
                visit(dependency, visiting | {name})
            resolved.append(name)

    for name in requested:
        visit(name, set())
    return requested, resolved


def detect():
    cpu = read("/proc/cpuinfo")
    pci = run("lspci", "-nnk", required=False)
    usb = run("lsusb", required=False)
    if not pci:
        rows = []
        for device in Path("/sys/bus/pci/devices").glob("*"):
            device_class = read(device / "class").strip()
            label = "VGA" if device_class.startswith("0x03") else device_class
            rows.append(f"{device.name} {label} [{read(device / 'vendor').strip().removeprefix('0x')}:{read(device / 'device').strip().removeprefix('0x')}]")
        pci = "\n".join(rows)
    if not usb:
        usb = "\n".join(f"ID {read(device / 'idVendor').strip()}:{read(device / 'idProduct').strip()}"
                        for device in Path("/sys/bus/usb/devices").glob("*") if (device / "idVendor").exists())
    gpu_lines = "\n".join(line for line in pci.splitlines()
                          if re.search(r"VGA|3D controller|Display controller", line))
    graphics = []
    for vendor, vendor_id in (("amd", "1002"), ("intel", "8086"), ("nvidia", "10de")):
        if f"[{vendor_id}:" in gpu_lines.lower():
            graphics.append(vendor)
    firmware = []
    for vendor, ids in {
        "amdgpu": ["1002"], "intel": ["8086", "8087"],
        "realtek": ["10ec", "0bda"], "mediatek": ["14c3", "0e8d"],
        "atheros": ["168c", "0cf3", "17cb"], "broadcom": ["14e4", "0a5c"],
        "cirrus": ["1013"], "nvidia": ["10de"],
    }.items():
        if any(re.search(rf"(?:\[|ID ){identifier}:", pci + usb, re.I) for identifier in ids):
            firmware.append("linux-firmware-" + vendor)
    return {
        "architecture": platform.machine(), "kernel": platform.release(),
        "os_release": read("/etc/os-release"),
        "cpu": "amd" if "AuthenticAMD" in cpu else "intel" if "GenuineIntel" in cpu else "unknown",
        "graphics": graphics, "firmware": firmware,
        "bluetooth": bool(list(Path("/sys/class/bluetooth").glob("hci*"))),
        "pci": pci, "usb": usb,
    }


def build_plan(args, hardware=None):
    hardware = hardware or detect()
    profile = args.profile or DEFAULT_PROFILE
    requested, modules = resolve(profile, args.include, args.without)
    packages, system_units, user_units, launchers = set(), set(), set(), set()
    files, checks, limitations, launcher_exceptions = {}, {}, {}, {}
    for name in modules:
        module = MANIFEST["modules"][name]
        packages.update(module["packages"])
        system_units.update(module["system_units"])
        user_units.update(module["user_units"])
        launchers.update(module["launchers"])
        files.update({target: (DATA / source).read_bytes()
                      for target, source in module["files"].items()})
        checks[name] = module["checks"]
        limitations[name] = module["limitations"]
        for desktop_id, exception in MANIFEST.get("launcher_exceptions", {}).get(name, {}).items():
            if not re.fullmatch(r"[A-Za-z0-9_.-]+\.desktop", desktop_id) or not exception.get("reason"):
                raise Refusal("Launcher exceptions require a desktop ID and a documented dependency reason")
            source = (DATA / exception["source"]).resolve()
            if not source.is_relative_to(DATA.resolve()):
                raise Refusal("Launcher exception sources must be inside cachyos/")
            content = source.read_bytes()
            desktop = configparser.ConfigParser(interpolation=None)
            desktop.read_string(content.decode())
            if desktop["Desktop Entry"].get("NoDisplay", "false").lower() != "true":
                raise Refusal(f"Launcher override must set NoDisplay=true: {desktop_id}")
            files[f"/usr/local/share/applications/{desktop_id}"] = content
            launcher_exceptions[desktop_id] = {"module": name, **exception}
    notes = ["No packages/data are removed when a module is omitted.",
             "Dependency/provider additions from pacman must be reviewed at its transaction prompt.",
             "Static checks do not establish hardware, GDM, suspend or recovery readiness."]
    blockers = []
    if "hardware" in modules:
        cpu = hardware["cpu"] if args.cpu == "auto" else args.cpu
        if cpu in ("amd", "intel"):
            packages.add(cpu + "-ucode")
        elif cpu != "existing":
            blockers.append("CPU microcode could not be selected; specify --cpu amd/intel/existing.")
        graphics = hardware["graphics"] if args.graphics == "auto" else args.graphics.split(",")
        if not graphics:
            blockers.append("GPU detection is inconclusive; select --graphics amd/intel/amd,intel/existing.")
        if "nvidia" in graphics:
            blockers.append("NVIDIA requires separate reviewed drivers; provision them and use --graphics existing.")
        if "amd" in graphics:
            packages.add("vulkan-radeon")
        if "intel" in graphics:
            packages.add("vulkan-intel")
            if args.intel_vaapi == "modern":
                packages.add("intel-media-driver")
            elif args.intel_vaapi == "legacy":
                packages.add("libva-intel-driver")
            elif args.intel_vaapi != "existing":
                blockers.append("Review Intel GPU generation and select --intel-vaapi modern/legacy/existing.")
        firmware = args.firmware or hardware["firmware"]
        if not firmware:
            blockers.append("No firmware selected; specify reviewed split --firmware packages.")
        packages.update(firmware)
        notes.append("Firmware detection covers known PCI/USB vendors only; review exact device IDs and missing-firmware logs.")
    if "network" in modules:
        firewall = args.firewall or "firewalld"
        wifi_backend = args.wifi_backend or "wpa_supplicant"
        packages.add(wifi_backend)
        packages.add(firewall)
        system_units.add(firewall + ".service")
        files["/etc/NetworkManager/conf.d/20-cachyos-wifi.conf"] = (
            "[device]\nwifi.backend=" + wifi_backend + "\n"
        ).encode()
        if args.bluetooth == "yes" or (args.bluetooth == "auto" and hardware["bluetooth"]):
            packages.update(["bluez", "bluez-utils"])
            system_units.add("bluetooth.service")
    if "power-memory" in modules:
        power = args.power or "tuned"
        if power == "tuned":
            packages.update(["tuned", "tuned-ppd"])
            system_units.update(["tuned.service", "tuned-ppd.service"])
        elif power == "power-profiles-daemon":
            packages.add("power-profiles-daemon")
            system_units.add("power-profiles-daemon.service")
        else:
            notes.append("Preserve existing power stack; application requires one active/enabled implementation.")
    if args.libvirt_proxy:
        if "virtualization-core" not in modules:
            raise Refusal("--libvirt-proxy requires virtualization-core")
        system_units.add("virtproxyd.socket")
    if set(launcher_exceptions) & launchers:
        raise Refusal("A launcher exception cannot hide a selected allowlisted application")
    files["/usr/local/share/cachyos-desktop/launcher-allowlist.json"] = (
        json.dumps(sorted(launchers), indent=2) + "\n").encode()
    if "flatpak-user" in modules and digest(files["/usr/local/share/cachyos-desktop/flathub.flatpakrepo"]) != FLATHUB_SHA256:
        raise Refusal("Bundled Flathub descriptor differs from its reviewed SHA-256 pin")
    if not all(re.fullmatch(r"[a-z0-9][a-z0-9@+_.-]*", package) for package in packages):
        raise Refusal("Invalid package name")
    return {
        "schema": 1, "profile": profile, "requested_modules": requested,
        "modules": modules, "hardware": hardware, "packages": sorted(packages),
        "files": {path: {"sha256": digest(content), "content": content.decode()}
                  for path, content in sorted(files.items())},
        "system_units": sorted(system_units), "global_user_units": sorted(user_units),
        "default_target": "graphical.target" if "desktop-common" in modules else None,
        "initial_user": args.initial_user,
        "apply_requirements": ["root", "--confirm", "--recovery-record with passing restore/rescue/fallback/initramfs tests"] +
        (["--initial-user naming an existing regular account"] if "niri" in modules else []),
        "initial_session": "Set Niri through AccountsService only if this account has no saved session; never replace a choice."
        if "niri" in modules else None,
        "expected_launchers": sorted(launchers), "checks": checks,
        "launcher_exceptions": launcher_exceptions,
        "reviewed_zram": args.reviewed_zram,
        "rollback_limitations": limitations, "notes": notes, "blockers": blockers,
        "commands": [["pacman", "-Syu"], ["pacman", "-S", "--needed", *sorted(packages)]],
    }


def enabled(unit):
    return run("systemctl", "is-enabled", unit, required=False) in {
        "enabled", "enabled-runtime", "linked", "linked-runtime", "alias"
    } or run("systemctl", "is-active", unit, required=False) == "active"


def zram_sources(root=Path("/")):
    sources = []
    for directory in ("etc/systemd", "usr/lib/systemd", "usr/local/lib/systemd", "run/systemd"):
        base = root / directory
        if (base / "zram-generator.conf").exists():
            sources.append(base / "zram-generator.conf")
        sources.extend(path for path in (base / "zram-generator.conf.d").glob("*.conf")
                       if path != root / "etc/systemd/zram-generator.conf.d/99-cachyos-desktop.conf")
    return sorted(sources)


def zram_conflicts(plan, root):
    problems = []
    for path in zram_sources(root):
        if not plan.get("reviewed_zram"):
            problems.append(f"Review existing zram policy before applying: {path}")
            continue
        parser = configparser.ConfigParser(interpolation=None, strict=False)
        try:
            parser.read_string(path.read_text())
        except configparser.Error:
            problems.append(f"Cannot safely interpret existing zram policy: {path}")
            continue
        for section in parser.sections():
            if section != "zram0":
                problems.append(f"Additional zram device needs manual reconciliation: {path}: [{section}]")
                continue
            allowed = {"zram-size", "compression-algorithm", "swap-priority", "fs-type", "writeback-device"}
            if set(parser[section]) - allowed or parser[section].get("fs-type", "swap") != "swap":
                problems.append(f"Advanced/non-swap zram configuration needs manual reconciliation: {path}")
            if path.parent.name == "zram-generator.conf.d" and path.name > "99-cachyos-desktop.conf":
                problems.append(f"Later zram drop-in could override managed policy: {path}")
    return problems


def wifi_backends(root=Path("/")):
    paths = [root / "etc/NetworkManager/NetworkManager.conf"]
    for directory in ("etc/NetworkManager/conf.d", "usr/lib/NetworkManager/conf.d", "run/NetworkManager/conf.d"):
        paths.extend((root / directory).glob("*.conf"))
    return {path: re.findall(r"^\s*wifi\.backend\s*=\s*(\S+)", read(path), re.M)
            for path in paths if path.is_file()}


def conflicts(plan, root=Path("/"), unit_enabled=enabled):
    problems = []
    for target, item in plan["files"].items():
        path = root / target.lstrip("/")
        if path.is_symlink() or any(parent.is_symlink() for parent in path.parents):
            problems.append(f"Managed path contains a symlink: {target}")
        elif path.exists() and (not path.is_file() or digest(path.read_bytes()) != item["sha256"]):
            problems.append(f"Existing file differs (will not overwrite): {target}")
    selected = plan["system_units"]
    if "network" in plan["modules"]:
        for unit in FIREWALL + ["connman.service", "dhcpcd.service", "systemd-networkd.service"]:
            if unit not in selected and unit_enabled(unit):
                problems.append(f"Existing firewall/network manager requires deliberate migration: {unit}")
        if "ufw.service" in selected and not (root / "etc/ufw/user.rules").exists():
            problems.append("--firewall ufw preserves a reviewed existing UFW setup; none was found")
        # Higher-priority or additional NM backend definitions need review.
        desired_backend = "iwd" if "iwd" in plan["packages"] else "wpa_supplicant"
        for path, backends in wifi_backends(root).items():
            if path.name != "20-cachyos-wifi.conf" and any(backend != desired_backend for backend in backends):
                problems.append(f"Review existing Wi-Fi backend setting: {path}")
    if "power-memory" in plan["modules"]:
        existing = [unit for unit in POWER if unit_enabled(unit)]
        chosen = [unit for unit in selected if unit in POWER]
        if chosen:
            problems.extend(f"Competing power manager: {unit}" for unit in existing if unit not in chosen)
        elif not existing or (set(existing) - {"tuned.service", "tuned-ppd.service"} and len(existing) > 1):
            problems.append("--power existing requires exactly one reviewed power stack")
        problems.extend(zram_conflicts(plan, root))
    if "virtualization-core" in plan["modules"]:
        problems.extend(f"Upstream monolithic libvirt migration required: {unit}"
                        for unit in MONOLITHIC if unit_enabled(unit))
        problems.extend(f"Remote libvirt listener must be reviewed/disabled: {unit}"
                        for unit in REMOTE_LIBVIRT if unit_enabled(unit))
        # Package installation must not implicitly approve broad grants.
        for path in (root / "etc/polkit-1/rules.d").glob("*.rules"):
            if path.name != "00-cachyos-libvirt-admin.rules" and re.search(r"libvirt|org\.libvirt", path.read_text()):
                problems.append(f"Review existing libvirt authorization rule outside this installer: {path}")
        for directory in ("etc/polkit-1/rules.d", "usr/share/polkit-1/rules.d"):
            for path in (root / directory).glob("*.rules"):
                if path.name < "00-cachyos-libvirt-admin.rules" and "addRule" in path.read_text():
                    problems.append(f"Polkit rule precedes the administrative libvirt policy; review ordering: {path}")
        for group in read(root / "etc/group").splitlines():
            fields = group.split(":")
            if fields[0] == "libvirt" and len(fields) == 4 and fields[3]:
                problems.append("Existing libvirt group membership grants powerful access; review before installation")
        for path in (root / "etc/libvirt").glob("*.conf"):
            if re.search(r'^\s*(?:auth_unix_rw|unix_sock_rw_perms|unix_sock_group)\s*=', path.read_text(), re.M):
                problems.append(f"Review existing libvirt socket authorization settings: {path}")
    if "containers-arm" in plan["modules"]:
        for directory in ("etc/binfmt.d", "usr/lib/binfmt.d", "run/binfmt.d"):
            for path in (root / directory).glob("*.conf"):
                if path.name != "cachyos-arm.conf" and "qemu" in path.read_text():
                    problems.append(f"Review existing all/foreign-architecture binfmt registration: {path}")
    return problems


def repository_check(packages):
    repos = run("pacman-conf", "--repo-list").splitlines()
    if not repos or not any("cachyos" in repo.lower() for repo in repos):
        raise Refusal("Expected configured CachyOS signed repositories")
    policies = {"global": run("pacman-conf", "SigLevel")}
    policies.update({repo: run("pacman-conf", "--repo", repo, "SigLevel") for repo in repos})
    for repo, policy in policies.items():
        tokens = policy.split()
        if (not ({"Required", "PackageRequired"} & set(tokens)) or
                {"Never", "Optional", "PackageNever", "PackageOptional", "TrustAll", "PackageTrustAll"} & set(tokens)):
            raise Refusal(f"Package signatures must be required and trusted for {repo}: {policy}")
    # No sync refresh here: only the explicit full -Syu transaction refreshes DBs.
    available = run("pacman", "-Si", *packages)
    return {
        "repositories": repos, "signature_policy": policies, "package_metadata": available,
        "servers": {repo: run("pacman-conf", "--repo", repo, "Server") for repo in repos},
        "dependency_transaction": run("pacman", "-Sp", "--needed", "--print-format", "%n %v %r", *packages),
        "upgrade_transaction": run("pacman", "-Sup", "--print-format", "%n %v %r"),
        "transaction_note": "Read-only estimates against current sync DBs. Review changed dependency/provider decisions again at pacman's actual transaction prompt after the full upgrade.",
        "foreign_packages": run("pacman", "-Qm", required=False),
    }


def target_check(plan):
    if platform.machine() != "x86_64":
        raise Refusal("Only supported CachyOS x86_64 hosts are accepted")
    release = dict(re.findall(r'^(\w+)=["\']?([^\n"\']+)', read("/etc/os-release"), re.M))
    if release.get("ID") != "cachyos" and not (release.get("ID") == "arch" and Path("/etc/cachyos-release").exists()):
        raise Refusal("Apply and repository verification require a supported installed CachyOS host")
    if (Path("/run/archiso").exists() or Path("/run/miso").exists() or
            re.search(r"(?:archisobasedir|misobasedir)=", read("/proc/cmdline"))):
        raise Refusal("Use the installed target, not a live installer session")
    if run("systemd-detect-virt", "--container", required=False):
        raise Refusal("Apply requires an installed host, not a container/chroot desktop test")
    run("pacman", "-Q", "cachyos-keyring")
    if plan["blockers"]:
        raise Refusal("; ".join(plan["blockers"]))


def launcher_inventory(expected, directories=None, desktop="GNOME"):
    # Precedence follows XDG_DATA_HOME then XDG_DATA_DIRS. Desktop IDs include
    # subdirectory names, not merely basenames. Never change a user override.
    if directories is None:
        directories = [Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))) / "applications"]
        directories += [Path(path) / "applications" for path in os.environ.get(
            "XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")]
    entries = {}
    for directory in directories:
        if not directory.is_dir():
            continue
        for path in sorted(directory.rglob("*.desktop")):
            desktop_id = str(path.relative_to(directory)).replace("/", "-")
            if desktop_id in entries:
                continue
            parser = configparser.ConfigParser(interpolation=None, strict=False)
            parser.optionxform = str
            try:
                parser.read_string(path.read_text())
                entry = dict(parser["Desktop Entry"])
            except (OSError, UnicodeError, configparser.Error, KeyError) as exc:
                entries[desktop_id] = {"path": str(path), "error": str(exc), "visible": False}
                continue
            sessions = set(desktop.split(":"))
            only = set(filter(None, entry.get("OnlyShowIn", "").split(";")))
            not_in = set(filter(None, entry.get("NotShowIn", "").split(";")))
            visible = (entry.get("Type", "Application") == "Application" and
                       entry.get("NoDisplay", "false").lower() != "true" and
                       entry.get("Hidden", "false").lower() != "true" and
                       (not only or bool(only & sessions)) and not bool(not_in & sessions))
            if entry.get("TryExec") and not shutil.which(entry["TryExec"]):
                visible = False
            entries[desktop_id] = {"path": str(path), "visible": visible,
                                   **{key: entry.get(key, "") for key in
                                      ("NoDisplay", "Hidden", "OnlyShowIn", "NotShowIn", "TryExec", "Exec")}}
    visible = {key for key, value in entries.items() if value["visible"]}
    return {"desktop": desktop, "entries": entries,
            "missing": sorted(set(expected) - visible), "unexpected": sorted(visible - set(expected)),
            "note": "Unexpected user-installed launchers are informational, not forbidden or automatically hidden. Test Fuzzel's actual filtering separately."}


def inventory(plan):
    return {
        "time": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "hardware": detect(), "plan": plan,
        "explicit_packages": run("pacman", "-Qqe", required=False).splitlines(),
        "installed_versions": run("pacman", "-Q", required=False).splitlines(),
        "enabled_system_units": run("systemctl", "list-unit-files", "--state=enabled", "--no-pager", required=False),
        "enabled_global_user_units": run("systemctl", "--global", "list-unit-files", "--state=enabled", "--no-pager", required=False),
        "failed_system_units": run("systemctl", "--failed", "--no-pager", required=False),
        "managed_files": {path: {"exists": Path(path).is_file(),
                                 "actual_sha256": digest(Path(path).read_bytes()) if Path(path).is_file() else None,
                                 "expected_sha256": value["sha256"]} for path, value in plan["files"].items()},
        "launchers": {desktop: launcher_inventory(plan["expected_launchers"], desktop=desktop)
                      for desktop in ("GNOME", "niri")},
    }


def save(path, value):
    # State may contain host/user metadata. Never commit it or expose it globally.
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    with open(temporary, "w", opener=lambda name, flags: os.open(name, flags, 0o600)) as stream:
        json.dump(value, stream, indent=2)
        stream.write("\n")
    temporary.replace(path)


def write_managed(plan):
    # Recheck after package installation; package-owned or user files may appear.
    problems = conflicts(plan)
    if problems:
        raise Refusal("\n".join(problems))
    for target, item in plan["files"].items():
        path = Path(target)
        if path.exists():
            continue  # Only identical regular files have survived conflict checks.
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("xb") as stream:
            stream.write(item["content"].encode())
        path.chmod(0o644)


def account_path(user):
    account = pwd.getpwnam(user)
    if account.pw_uid < 1000 or account.pw_uid == 65534:
        raise Refusal("--initial-user must name an existing regular local account")
    result = run("busctl", "call", "org.freedesktop.Accounts", "/org/freedesktop/Accounts",
                 "org.freedesktop.Accounts", "FindUserByName", "s", user)
    match = re.fullmatch(r'o "(/org/freedesktop/Accounts/User\d+)"', result)
    if not match:
        raise Refusal("AccountsService returned an unexpected user object")
    return match[1]


def initial_session(user):
    path = account_path(user)
    properties = {prop: run("busctl", "get-property", "org.freedesktop.Accounts", path,
                           "org.freedesktop.Accounts.User", prop)
                  for prop in ("Session", "XSession", "SessionType")}
    if all(value == 's ""' for value in properties.values()):
        mutate("busctl", "call", "org.freedesktop.Accounts", path,
               "org.freedesktop.Accounts.User", "SetSession", "s", "niri")
        mutate("busctl", "call", "org.freedesktop.Accounts", path,
               "org.freedesktop.Accounts.User", "SetSessionType", "s", "wayland")
    else:
        print(f"Preserving {user}'s saved GDM session: {properties}")


def content_checks(plan, installed=True):
    """Check installed contents, not candidate names alone, before enablement."""
    for unit in plan["system_units"]:
        run("systemctl", "cat", unit)
        if run("systemctl", "show", unit, "--property=LoadState", "--value") == "masked":
            raise Refusal(f"Selected unit is masked; review manually: {unit}")
    for unit in plan["global_user_units"]:
        if not installed and f"/etc/systemd/user/{unit}" in plan["files"]:
            continue
        if not any((Path(directory) / unit).is_file() for directory in ("/etc/systemd/user", "/usr/lib/systemd/user")):
            raise Refusal(f"Selected user unit is not supplied: {unit}")
    if "gnome-minimal" in plan["modules"]:
        if not list(Path("/usr/share/wayland-sessions").glob("gnome*.desktop")):
            raise Refusal("GNOME Wayland session descriptor missing")
    if "desktop-common" in plan["modules"]:
        if "pam_gnome_keyring.so" not in read("/etc/pam.d/gdm-password"):
            raise Refusal("Verify GDM/keyring PAM integration manually; installer will not edit PAM")
        if "flatpak-user" in plan["modules"] and not re.search(r"flatpak.*\.so$", run("pacman", "-Qlq", "gnome-software"), re.M):
            raise Refusal("Installed GNOME Software does not supply its Flatpak integration plugin")
    if "niri" in plan["modules"]:
        session = read("/usr/share/wayland-sessions/niri.desktop")
        if "niri-session" not in session or not Path("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1").is_file():
            raise Refusal("Verify packaged niri-session integration and polkit-gnome's agent provider")
        run("niri", "validate", "--config", "/etc/niri/config.kdl" if installed else str(DATA / "config/niri.kdl"))
    if "security-keys" in plan["modules"] and not shutil.which("pamu2fcfg"):
        raise Refusal("pam-u2f does not supply the required pamu2fcfg executable")
    if "hardware" in plan["modules"]:
        run("python", "-c", "import ctypes; [ctypes.CDLL(n) for n in ('libEGL.so.1','libGLESv2.so.2','libGL.so.1','libgbm.so.1')]")
    if "virtualization-core" in plan["modules"]:
        if "kvm" not in run("qemu-system-x86_64", "-accel", "help").lower():
            raise Refusal("Selected QEMU lacks KVM support")
        if not Path("/dev/kvm").exists():
            raise Refusal("/dev/kvm missing: review firmware virtualization support and CPU module binding")
        for package, pattern in (("edk2-ovmf", r"(?i)ovmf.*\.(fd|qcow2)$"), ("swtpm", r"/swtpm_setup$")):
            if not re.search(pattern, run("pacman", "-Qlq", package), re.M):
                raise Refusal(f"Required firmware/TPM tooling not found in {package}")
    if "virtualization-3d" in plan["modules"]:
        devices = run("qemu-system-x86_64", "-device", "help")
        displays = run("qemu-system-x86_64", "-display", "help")
        audio = run("qemu-system-x86_64", "-audio", "driver=help")
        for text, capabilities in ((devices, ("virtio-gpu-gl", "qxl", "usb-redir")),
                                   (displays, ("egl-headless", "spice-app")), (audio, ("pipewire",))):
            if any(capability not in text for capability in capabilities):
                raise Refusal("Selected QEMU backends do not supply all requested 3D/display/audio/USB capabilities")
    if "virtualization-arm" in plan["modules"]:
        for command in ("qemu-system-arm", "qemu-system-aarch64"):
            if "tcg" not in run(command, "-accel", "help"):
                raise Refusal(f"{command} lacks TCG")
        firmware = run("pacman", "-Qlq", "edk2-aarch64")
        arm_firmware = run("pacman", "-Qlq", "qemu-system-arm-firmware")
        if (not re.search(r"/(?:QEMU_EFI|AAVMF_CODE)\.fd$", firmware, re.M) or
                not re.search(r"/(?:QEMU_VARS|AAVMF_VARS)\.fd$", firmware, re.M) or
                not re.search(r"/edk2-arm-code\.fd$", arm_firmware, re.M) or
                not re.search(r"/edk2-arm-vars\.fd$", arm_firmware, re.M)):
            raise Refusal("Verify both ARM32 and AArch64 firmware code/variable provider contents")
    if "containers-arm" in plan["modules"]:
        for command in ("qemu-arm-static", "qemu-aarch64-static"):
            if not shutil.which(command):
                raise Refusal(f"Required static interpreter missing: {command}")


def recovery_check(filename):
    if not filename:
        raise Refusal("Supply --recovery-record; start with cachyos/recovery.example.json")
    record = json.loads(Path(filename).read_text())
    return validate_recovery_record(record)


def validate_recovery_record(record):
    if not isinstance(record, dict):
        raise Refusal("Recovery record must be a JSON object")
    if record.get("external_backup_confirmed") is not True or not record.get("backup_location"):
        raise Refusal("Recovery record must identify an external backup")
    for name in ("backup_restore_test", "rescue_boot_test", "fallback_boot_test", "initramfs_test"):
        test = record.get(name, {})
        if not isinstance(test, dict) or test.get("result") != "passed" or not test.get("details"):
            raise Refusal(f"Recovery record needs a passing {name} with details")
        try:
            datetime.date.fromisoformat(test.get("date", ""))
        except (TypeError, ValueError) as exc:
            raise Refusal(f"Recovery test {name} needs an ISO date (YYYY-MM-DD)") from exc
    target = record.get("target", {})
    for field in ("kernel", "bootloader", "initramfs_tool", "root_filesystem"):
        if not isinstance(target, dict) or not target.get(field):
            raise Refusal(f"Recovery record needs target.{field}")
    return record


def apply(args, plan):
    if os.geteuid() != 0:
        raise Refusal("Only apply requires root; review plan as your normal user first")
    if not args.confirm:
        raise Refusal("Review plan first, then explicitly pass --confirm")
    target_check(plan)
    recovery_check(args.recovery_record)
    recovery = Path(args.recovery_record)
    # Root will execute this repository's reviewed declarations. No shell eval.
    problems = conflicts(plan)
    if problems:
        raise Refusal("\n".join(problems))
    if "niri" in plan["modules"]:
        if not args.initial_user:
            raise Refusal("Select --initial-user for first-login Niri; an existing GDM choice will be preserved")
        # AccountsService may be supplied by the pending GDM transaction.
        account = pwd.getpwnam(args.initial_user)
        if account.pw_uid < 1000 or account.pw_uid == 65534:
            raise Refusal("--initial-user must name an existing regular local account")
    provenance = repository_check(plan["packages"])
    STATE.mkdir(mode=0o700, parents=True, exist_ok=True)
    # flock prevents concurrent runs without assuming a stale PID is safe to remove.
    import fcntl
    with (STATE / "apply.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
        record = STATE / "runs" / stamp
        save(record / "before.json", inventory(plan))
        save(record / "provenance.json", provenance)
        save(record / "recovery.json", {"record_sha256": digest(recovery.read_bytes()),
                                         "path": str(recovery.resolve()), "status": "operator supplied; not independently certified"})
        try:
            mutate("pacman", "-Syu")
            # Recheck availability and signature policy against the refreshed DBs.
            save(record / "provenance.json", repository_check(plan["packages"]))
            mutate("pacman", "-S", "--needed", *plan["packages"])
            content_checks(plan, installed=False)
            write_managed(plan)
            content_checks(plan)
            mutate("systemctl", "daemon-reload")
            if plan["global_user_units"]:
                mutate("systemctl", "--global", "enable", *plan["global_user_units"])
            if plan["system_units"]:
                mutate("systemctl", "enable", *plan["system_units"])
            if plan["default_target"]:
                mutate("systemctl", "set-default", plan["default_target"])
            if "niri" in plan["modules"]:
                initial_session(args.initial_user)
            save(STATE / "current.json", plan)
            save(record / "result.json", {"status": "configured; runtime acceptance pending"})
        except Exception as exc:
            save(record / "result.json", {"status": "incomplete; no automatic rollback", "error": str(exc)})
            raise
        finally:
            save(record / "after.json", inventory(plan))
    print(f"Configuration recorded in {record}. No reboot or live service starts were requested.")
    print("Reboot deliberately, test both sessions and complete docs/cachyos-install.md acceptance checks.")


def prompt(message, default=None):
    suffix = f" [{default}]" if default else ""
    try:
        answer = input(f"{message}{suffix}: ").strip()
    except EOFError as exc:
        raise Refusal("Setup cancelled: interactive input ended") from exc
    answer = answer or default
    if not answer:
        raise Refusal("Setup cancelled; a required answer was left blank")
    return answer


def recovery_wizard(destination, hardware):
    print("Recovery must be tested, not assumed. Only record tests that actually passed.")
    print("For each test enter its date and evidence: YYYY-MM-DD description. Blank cancels.")
    record = {
        "external_backup_confirmed": True,
        "backup_location": prompt("Location of your tested EXTERNAL backup (not a local snapshot)"),
        "target": {"kernel": hardware["kernel"]},
        "secure_boot": {"state": "unknown", "result": "pending", "details": "Validate separately on actual hardware"},
    }
    for name, description in (
        ("backup_restore_test", "Successful external-backup restore test"),
        ("rescue_boot_test", "Successful rescue-medium boot test"),
        ("fallback_boot_test", "Successful fallback-kernel boot test"),
        ("initramfs_test", "Successful kernel/initramfs regeneration test"),
    ):
        answer = prompt(description)
        date, _, details = answer.partition(" ")
        record[name] = {"date": date, "details": details.strip(), "result": "passed"}
    record["target"]["bootloader"] = prompt("Installed bootloader")
    candidates = [tool for tool in ("mkinitcpio", "dracut") if shutil.which(tool)]
    record["target"]["initramfs_tool"] = prompt("Installed initramfs tooling", candidates[0] if len(candidates) == 1 else None)
    filesystem = run("findmnt", "--noheadings", "--output", "FSTYPE", "/", required=False)
    record["target"]["root_filesystem"] = prompt("Root filesystem", filesystem or None)
    validate_recovery_record(record)
    save(destination, record)
    return str(destination)


def selection_arguments(args):
    """Forward only supported options, never construct a shell command."""
    result = []
    for name in ("profile", "cpu", "graphics", "intel_vaapi", "bluetooth", "wifi_backend",
                 "firewall", "power", "initial_user", "recovery_record"):
        value = getattr(args, name)
        if value is not None:
            result.extend(["--" + name.replace("_", "-"), value])
    for name in ("include", "without", "firmware"):
        for value in getattr(args, name):
            result.extend(["--" + name, value])
    for name in ("libvirt_proxy", "reviewed_zram"):
        if getattr(args, name):
            result.append("--" + name.replace("_", "-"))
    return result


def setup(args):
    """Interactive single-command installation; personal dotfiles stay opt-in."""
    if os.geteuid() == 0:
        raise Refusal("Run make setup as your normal user; it will request sudo")
    if not sys.stdin.isatty():
        raise Refusal("make setup needs an interactive terminal; use plan for a non-mutating preview")
    if args.profile is not None or args.include or args.without or args.libvirt_proxy:
        raise Refusal("Setup uses a fixed workstation selection; run make setup without feature arguments")
    hardware = detect()
    probe = argparse.Namespace(**vars(args))
    probe.profile, probe.include, probe.without = "custom", [], []
    probe.libvirt_proxy = False
    target_check(build_plan(probe, hardware))
    args.profile = DEFAULT_PROFILE
    args.initial_user = args.initial_user or pwd.getpwuid(os.getuid()).pw_name
    _, modules = resolve(args.profile, args.include, args.without)
    if "network" in modules:
        if args.firewall is None:
            args.firewall = "ufw" if enabled("ufw.service") or Path("/etc/ufw/user.rules").is_file() else "firewalld"
        if args.wifi_backend is None:
            backends = {backend for values in wifi_backends().values() for backend in values}
            if len(backends) > 1 or backends - {"iwd", "wpa_supplicant"}:
                raise Refusal("Conflicting/unknown existing NetworkManager Wi-Fi backends; review before setup")
            args.wifi_backend = next(iter(backends), "wpa_supplicant")
    if "power-memory" in modules:
        if args.power is None:
            args.power = "existing" if any(enabled(unit) for unit in POWER) else (
                "power-profiles-daemon" if run("pacman", "-Qq", "power-profiles-daemon", required=False) else "tuned")
        sources = zram_sources()
        if sources and not args.reviewed_zram:
            print("Existing zram policy (files will be kept, not replaced):")
            for path in sources:
                print(f"--- {path}\n{path.read_text()}")
            answer = prompt("Layer the reviewed zram0 policy: min(ram,8192) MiB, priority 100, zstd(level=1), no writeback? yes/no", "no")
            if answer.lower() not in ("yes", "y"):
                raise Refusal("Setup cancelled; existing zram policy was not approved for layering")
            args.reviewed_zram = True
    if "hardware" in modules and "intel" in (hardware["graphics"] if args.graphics == "auto" else args.graphics.split(",")):
        if args.intel_vaapi == "review":
            args.intel_vaapi = prompt("Intel VA-API provider for your GPU generation: modern / legacy / existing")
            if args.intel_vaapi not in ("modern", "legacy", "existing"):
                raise Refusal("Unknown Intel VA-API choice")
    plan = build_plan(args, hardware)
    if plan["blockers"]:
        raise Refusal("; ".join(plan["blockers"]))
    print("Standard workstation installation; existing firewall/power choices are preserved where detected.")
    print("Checking the signed repository plan with sudo (no installation yet)...", flush=True)
    command = ["sudo", sys.executable, str(Path(__file__).resolve())]
    verified = subprocess.run([*command, "plan", *selection_arguments(args), "--verify-repositories"],
                              text=True, stdout=subprocess.PIPE)
    if verified.returncode:
        raise Refusal("Pre-install review failed; no desktop installation was attempted")
    plan = json.loads(verified.stdout)
    if plan["existing_conflicts"]:
        raise Refusal("\n".join(plan["existing_conflicts"]))
    state = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "cachyos-desktop"
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    preview = state / f"plan-{stamp}.json"
    save(preview, plan)
    print("\nModules: " + ", ".join(plan["modules"]))
    print("Packages (explicit selections; pacman also reviews dependencies):")
    print(textwrap.fill(" ".join(plan["packages"]), width=88, initial_indent="  ", subsequent_indent="  "))
    print("System units to enable: " + ", ".join(plan["system_units"]))
    print("Global USER units to enable: " + ", ".join(plan["global_user_units"]))
    print("Managed system files:\n  " + "\n  ".join(plan["files"]))
    print(f"Full file contents, hashes, dependency/upgrade estimates and limitations: {preview}")
    print("No personal dotfile/theme/shell changes, container/VM instances, automatic authentication or reboot will be performed.")
    if args.recovery_record:
        recovery_check(args.recovery_record)
    else:
        previous_records = sorted(state.glob("recovery*.json"))
        previous = previous_records[-1] if previous_records else None
        reuse = previous is not None and prompt("Reuse the previously recorded recovery tests? yes/no", "no").lower() in ("yes", "y")
        if reuse:
            recovery_check(str(previous))
            args.recovery_record = str(previous)
        else:
            args.recovery_record = recovery_wizard(state / f"recovery-{stamp}.json", hardware)
    if prompt("Type INSTALL to authorize this full system upgrade and installation") != "INSTALL":
        raise Refusal("Setup cancelled; no desktop installation was attempted")
    if subprocess.run([*command, "apply", *selection_arguments(args), "--confirm"]).returncode:
        raise Refusal("Installation incomplete; inspect the installer run inventory before retrying")
    print("make setup: standard workstation installed, including containers, 3D/ARM virtualization, Tailscale and security-key tools.")
    print("Reboot when ready; choose Niri or GNOME in GDM.")
    print("Personal dotfiles remain unchanged. make local is a separate, optional preference workflow.")


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("command", choices=("setup", "plan", "apply", "inventory", "check", "launchers"), nargs="?", default="plan")
    result.add_argument("--profile", choices=MANIFEST["profiles"], help="Maintenance-only subsets; default workstation. Not accepted by setup")
    result.add_argument("--include", action="append", default=[], metavar="MODULE", help="Maintenance-only; not accepted by setup")
    result.add_argument("--without", action="append", default=[], metavar="MODULE", help="Maintenance-only; not accepted by setup")
    result.add_argument("--cpu", choices=("auto", "amd", "intel", "existing"), default="auto")
    result.add_argument("--graphics", choices=("auto", "amd", "intel", "amd,intel", "existing"), default="auto")
    result.add_argument("--intel-vaapi", choices=("review", "modern", "legacy", "existing"), default="review")
    result.add_argument("--firmware", action="append", default=[], metavar="PACKAGE",
                        help="Override firmware autodetection; repeat for reviewed split firmware providers")
    result.add_argument("--bluetooth", choices=("auto", "yes", "no"), default="auto")
    result.add_argument("--wifi-backend", choices=("wpa_supplicant", "iwd"), help="setup detects existing backend; otherwise wpa_supplicant")
    result.add_argument("--firewall", choices=("firewalld", "ufw"), help="setup preserves existing UFW; otherwise firewalld")
    result.add_argument("--power", choices=("tuned", "power-profiles-daemon", "existing"), help="setup preserves an existing stack; otherwise tuned")
    result.add_argument("--reviewed-zram", action="store_true", help="Explicitly approve layering the managed zram0 policy over reviewed existing defaults")
    result.add_argument("--libvirt-proxy", action="store_true", help="Also enable the local compatibility proxy socket")
    result.add_argument("--initial-user", help="Existing regular account whose unset GDM session should initially be Niri")
    result.add_argument("--verify-repositories", action="store_true", help="Read-only CachyOS/pacman checks using current sync DBs")
    result.add_argument("--recovery-record", help="External operator-authored recovery test record, required for apply")
    result.add_argument("--confirm", action="store_true", help="Explicitly authorize apply after reviewing the plan")
    return result


def main(argv=None):
    args = parser().parse_args(argv)
    try:
        if args.command == "setup":
            setup(args)
            return 0
        plan = build_plan(args)
        if args.command == "apply":
            apply(args, plan)
        elif args.command == "plan":
            plan["existing_conflicts"] = conflicts(plan)
            if args.verify_repositories:
                target_check(plan)
                plan["provenance"] = repository_check(plan["packages"])
            print(json.dumps(plan, indent=2))
        elif args.command == "launchers":
            allowlist = Path("/usr/local/share/cachyos-desktop/launcher-allowlist.json")
            expected = json.loads(allowlist.read_text()) if allowlist.is_file() else plan["expected_launchers"]
            print(json.dumps({desktop: launcher_inventory(expected, desktop=desktop)
                              for desktop in ("GNOME", "niri")}, indent=2))
        else:
            # Inventory/check use the actual last-applied modules, not today's
            # default profile. A changed selection requires an explicit new plan.
            if (STATE / "current.json").is_file():
                plan = json.loads((STATE / "current.json").read_text())
            report = inventory(plan)
            if args.command == "check":
                problems = conflicts(plan)
                problems.extend(f"Managed file missing: {path}" for path in plan["files"] if not Path(path).is_file())
                installed_packages = set(run("pacman", "-Qq", required=False).splitlines())
                problems.extend(f"Selected package missing: {package}" for package in plan["packages"] if package not in installed_packages)
                try:
                    content_checks(plan)
                except Refusal as exc:
                    problems.append(str(exc))
                for unit in plan["system_units"]:
                    if not enabled(unit):
                        problems.append(f"Selected unit is not enabled/active: {unit}")
                for unit in plan["global_user_units"]:
                    if not list(Path("/etc/systemd/user").glob(f"*.wants/{unit}")):
                        problems.append(f"Selected global user unit not enabled: {unit}")
                if plan["default_target"] and run("systemctl", "get-default", required=False) != plan["default_target"]:
                    problems.append("Default target does not match the graphical desktop plan")
                report["static_problems"] = problems
                report["runtime_acceptance"] = "PENDING: perform and record the manual checks; static success is not certification"
                print(json.dumps(report, indent=2))
                return 1 if problems else 0
            print(json.dumps(report, indent=2))
    except (Refusal, OSError, KeyError, ValueError, configparser.Error) as exc:
        print(f"cachyos: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
