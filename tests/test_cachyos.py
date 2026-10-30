"""Exercise the installer without root, pacman, downloads or host mutations."""

import copy
import importlib.util
import io
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from contextlib import ExitStack, redirect_stdout
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("cachyos", ROOT / "scripts/cachyos.py")
cachyos = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(cachyos)
HARDWARE = {
    "architecture": "x86_64", "kernel": "test-cachyos", "os_release": "ID=cachyos\n",
    "cpu": "amd", "graphics": ["amd"], "firmware": ["linux-firmware-amdgpu"],
    "bluetooth": False, "pci": "", "usb": "",
}


def plan(*arguments, hardware=None):
    return cachyos.build_plan(cachyos.parser().parse_args(arguments), hardware or copy.deepcopy(HARDWARE))


class ModuleTests(unittest.TestCase):
    def test_every_module_is_reviewable(self):
        required = {"packages", "dependencies", "files", "system_units", "user_units", "checks", "limitations", "launchers"}
        for module in cachyos.MANIFEST["modules"].values():
            self.assertLessEqual(required, module.keys())
            self.assertTrue(module["checks"])
            self.assertTrue(module["limitations"])
            for source in module["files"].values():
                self.assertTrue((cachyos.DATA / source).is_file())

    def test_default_desktop_has_both_sessions_not_optional_daemons(self):
        result = plan("--profile", "desktop")
        self.assertLessEqual({"niri", "gnome-minimal", "recovery"}, set(result["modules"]))
        self.assertNotIn("virtualization-core", result["modules"])
        self.assertNotIn("virt-manager.desktop", result["expected_launchers"])
        self.assertNotIn("tailscaled.service", result["system_units"])
        self.assertEqual(result["default_target"], "graphical.target")
        self.assertEqual(result["blockers"], [])

    def test_setup_and_preview_use_the_same_full_workstation_defaults(self):
        default = plan()
        setup = plan("setup")
        self.assertEqual(default["profile"], "workstation")
        self.assertEqual(set(setup["modules"]), set(cachyos.MANIFEST["modules"]))
        for key in ("profile", "modules", "packages", "system_units", "global_user_units", "files"):
            self.assertEqual(default[key], setup[key])
        self.assertLessEqual({"podman", "distrobox", "virt-manager", "virglrenderer", "qemu-audio-pipewire",
                              "qemu-system-arm", "qemu-system-aarch64", "qemu-user-static", "tailscale", "pam-u2f", "yubico-pam"},
                             set(setup["packages"]))

    def test_complete_profile_can_omit_independent_features(self):
        result = plan("--profile", "complete", "--without", "virtualization-core", "--without", "containers")
        self.assertNotIn("virt-manager", result["packages"])
        self.assertNotIn("podman", result["packages"])
        self.assertIn("tailscale", result["packages"])

    def test_dependency_resolution_and_deduplication(self):
        result = plan("--profile", "custom", "--include", "virtualization-3d", "--include", "virtualization-arm")
        self.assertLess(result["modules"].index("virtualization-core"), result["modules"].index("virtualization-3d"))
        self.assertEqual(result["modules"].count("virtualization-core"), 1)
        self.assertNotIn("niri", result["modules"])
        self.assertIsNone(result["default_target"])
        self.assertIn("virt-manager.desktop", result["expected_launchers"])
        self.assertNotIn("virtproxyd.socket", result["system_units"])
        self.assertIn("edk2-aarch64", result["packages"])
        self.assertIn("qemu-system-arm-firmware", result["packages"])
        self.assertNotIn("edk2-armvirt", result["packages"])

    def test_omitted_dependency_is_not_silently_reinstalled(self):
        with self.assertRaisesRegex(cachyos.Refusal, "explicitly omitted"):
            plan("--include", "virtualization-3d", "--without", "virtualization-core")
        with self.assertRaises(cachyos.Refusal):
            plan("--without", "base")
        with self.assertRaises(cachyos.Refusal):
            plan("--include", "typo")

    def test_packages_are_explicit_not_broad_groups(self):
        result = plan("--profile", "complete", "--include", "virtualization-3d", "--include", "virtualization-arm", "--include", "containers-arm")
        forbidden = {"gnome", "gnome-extra", "qemu-full", "qemu-user-static-binfmt", "firefox", "chromium", "rocm", "openssh"}
        self.assertFalse(forbidden & set(result["packages"]))
        for unit in result["system_units"]:
            self.assertNotIn(unit, cachyos.MONOLITHIC + cachyos.REMOTE_LIBVIRT + ["dnsmasq.service", "sshd.service"])
        self.assertNotIn("pipewire.socket", result["system_units"])
        self.assertIn("pipewire.socket", result["global_user_units"])
        self.assertEqual(result["commands"][0], ["pacman", "-Syu"])
        self.assertNotIn("--noconfirm", sum(result["commands"], []))

    def test_hardware_selection_is_specific(self):
        result = plan()
        self.assertIn("amd-ucode", result["packages"])
        self.assertIn("vulkan-radeon", result["packages"])
        self.assertNotIn("intel-ucode", result["packages"])
        self.assertNotIn("linux-firmware", result["packages"])
        self.assertIn("bluez", result["packages"])
        self.assertIn("bluez-utils", result["packages"])
        self.assertNotIn("bluetooth.service", result["system_units"])
        result = plan("--bluetooth", "yes", "--firmware", "linux-firmware-realtek")
        self.assertIn("bluetooth.service", result["system_units"])
        self.assertIn("linux-firmware-realtek", result["packages"])
        self.assertNotIn("linux-firmware-amdgpu", result["packages"])

    def test_intel_generation_requires_review(self):
        hardware = {**HARDWARE, "cpu": "intel", "graphics": ["intel"]}
        self.assertTrue(plan(hardware=hardware)["blockers"])
        result = plan("--intel-vaapi", "modern", hardware=hardware)
        self.assertEqual(result["blockers"], [])
        self.assertIn("intel-media-driver", result["packages"])
        self.assertIn("intel-ucode", result["packages"])
        existing = plan("--intel-vaapi", "existing", hardware=hardware)
        self.assertEqual(existing["blockers"], [])
        self.assertNotIn("intel-media-driver", existing["packages"])

    def test_unsupported_graphics_is_not_silently_provisioned(self):
        self.assertTrue(plan(hardware={**HARDWARE, "graphics": ["nvidia"]})["blockers"])
        self.assertEqual(plan("--graphics", "existing", hardware={**HARDWARE, "graphics": ["nvidia"]})["blockers"], [])

    def test_proxy_is_explicit(self):
        with self.assertRaises(cachyos.Refusal):
            plan("--profile", "desktop", "--libvirt-proxy")
        self.assertIn("virtproxyd.socket", plan("--include", "virtualization-core", "--libvirt-proxy")["system_units"])

    def test_flathub_pin_and_user_only_deferred_registration(self):
        descriptor = cachyos.DATA / "vendor/flathub.flatpakrepo"
        self.assertEqual(cachyos.digest(descriptor.read_bytes()), cachyos.FLATHUB_SHA256)
        service = (cachyos.DATA / "config/cachyos-flathub.service").read_text()
        self.assertIn("remote-add --user --if-not-exists flathub /", service)
        self.assertIn("ConditionUser=!root", service)
        self.assertIn("Restart=on-failure", service)
        self.assertNotIn("https://", service)
        self.assertIn("OnActiveSec=15s", (cachyos.DATA / "config/cachyos-flathub.timer").read_text())

    @unittest.skipUnless(shutil.which("niri"), "niri unavailable")
    def test_niri_fallback_validates(self):
        result = subprocess.run(["niri", "validate", "--config", str(cachyos.DATA / "config/niri.kdl")], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_fallback_has_no_personal_theme_or_home_files(self):
        result = plan()
        self.assertTrue(all(path.startswith(("/etc/", "/usr/local/")) for path in result["files"]))
        self.assertNotIn("starship init", "\n".join(item["content"] for item in result["files"].values()))
        config = result["files"]["/etc/niri/config.kdl"]["content"]
        self.assertEqual(config.count('spawn-at-startup "swayidle"'), 1)
        self.assertIn('"before-sleep" "swaylock -f"', config)
        self.assertIn('"timeout" "300"', config)
        self.assertIn('"timeout" "600"', config)
        self.assertIn('"after-resume" "niri msg action power-on-monitors"', config)

    def test_launcher_hiding_requires_selected_module_documentation(self):
        with tempfile.TemporaryDirectory() as directory:
            data = Path(directory)
            (data / "override.desktop").write_text("[Desktop Entry]\nType=Application\nNoDisplay=true\n")
            manifest = copy.deepcopy(cachyos.MANIFEST)
            manifest["launcher_exceptions"] = {"base": {"dependency.desktop": {
                "source": "override.desktop", "reason": "Required CLI dependency also ships this unwanted GUI"
            }}}
            with patch.object(cachyos, "DATA", data), patch.object(cachyos, "MANIFEST", manifest):
                result = plan("--profile", "custom")
                self.assertIn("/usr/local/share/applications/dependency.desktop", result["files"])
                self.assertIn("dependency.desktop", result["launcher_exceptions"])
                manifest["launcher_exceptions"]["base"]["btop.desktop"] = manifest["launcher_exceptions"]["base"].pop("dependency.desktop")
                with self.assertRaisesRegex(cachyos.Refusal, "allowlisted"):
                    plan("--profile", "custom")


class ConflictTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def put(self, name, text):
        path = self.root / name.lstrip("/")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def conflicts(self, result=None, active=()):
        return cachyos.conflicts(result or plan(), self.root, lambda unit: unit in active)

    def test_fresh_and_identical_reapply_are_safe(self):
        result = plan()
        self.assertEqual(self.conflicts(result), [])
        for path, item in result["files"].items():
            self.put(path, item["content"])
        self.assertEqual(self.conflicts(result), [])

    def test_existing_config_is_never_overwritten(self):
        path = self.put("/etc/niri/config.kdl", "personal config")
        self.assertTrue(any("will not overwrite" in error for error in self.conflicts()))
        self.assertEqual(path.read_text(), "personal config")

    def test_symlinked_files_and_parents_are_refused(self):
        source = self.put("source", "personal config")
        self.put("/etc/niri/placeholder", "")
        (self.root / "etc/niri/config.kdl").symlink_to(source)
        self.assertTrue(any("symlink" in error for error in self.conflicts()))
        result = plan("--profile", "custom")
        (self.root / "usr").symlink_to(self.root / "etc")
        self.assertTrue(any("symlink" in error for error in self.conflicts(result)))

    def test_conflicting_managers_refuse_no_automatic_stopping(self):
        errors = self.conflicts(active=["ufw.service", "tlp.service", "systemd-networkd.service"])
        self.assertTrue(any("ufw" in error for error in errors))
        self.assertTrue(any("tlp" in error for error in errors))
        self.assertTrue(any("systemd-networkd" in error for error in errors))

    def test_preserve_reviewed_ufw_instead_of_enabling_both(self):
        result = plan("--firewall", "ufw")
        self.assertNotIn("firewalld.service", result["system_units"])
        self.assertTrue(any("none was found" in error for error in self.conflicts(result)))
        self.put("/etc/ufw/user.rules", "existing rules")
        self.assertEqual(self.conflicts(result, ["ufw.service"]), [])

    def test_vendor_zram_and_nm_backend_need_review(self):
        self.put("/usr/lib/systemd/zram-generator.conf.d/vendor.conf", "[zram0]")
        self.put("/etc/NetworkManager/conf.d/personal.conf", "[device]\nwifi.backend=iwd\n")
        errors = self.conflicts()
        self.assertTrue(any("zram" in error for error in errors))
        self.assertTrue(any("Wi-Fi" in error for error in errors))

    def test_reviewed_vendor_zram_can_be_layered_without_editing_it(self):
        path = self.put("/usr/lib/systemd/zram-generator.conf", "[zram0]\nzram-size=ram / 2\ncompression-algorithm=lz4\n")
        result = plan("--reviewed-zram")
        self.assertEqual(self.conflicts(result), [])
        self.assertEqual(path.read_text(), "[zram0]\nzram-size=ram / 2\ncompression-algorithm=lz4\n")
        self.assertNotIn("/etc/systemd/zram-generator.conf", result["files"])
        override = result["files"]["/etc/systemd/zram-generator.conf.d/99-cachyos-desktop.conf"]["content"]
        self.assertIn("writeback-device =\n", override)
        self.assertIn("zstd(level=1)", override)

    def test_review_does_not_bypass_complex_zram_conflicts(self):
        result = plan("--reviewed-zram")
        for text in ("[zram1]\nzram-size=ram\n", "[zram0]\nfs-type=ext4\n", "[zram0]\nunknown-policy=1\n"):
            with self.subTest(text=text):
                self.put("/etc/systemd/zram-generator.conf", text)
                self.assertTrue(self.conflicts(result))
        self.put("/etc/systemd/zram-generator.conf", "[zram0]\n")
        self.put("/etc/systemd/zram-generator.conf.d/zz-personal.conf", "[zram0]\nzram-size=ram\n")
        self.assertTrue(any("Later zram" in error for error in self.conflicts(result)))

    def test_existing_identical_wifi_backend_is_preserved(self):
        self.put("/etc/NetworkManager/NetworkManager.conf", "[device]\nwifi.backend=iwd\n")
        self.assertEqual(self.conflicts(plan("--wifi-backend", "iwd")), [])
        self.assertTrue(any("Wi-Fi" in error for error in self.conflicts()))

    def test_monolithic_libvirt_is_not_automatically_converted(self):
        result = plan("--include", "virtualization-core")
        errors = self.conflicts(result, ["libvirtd.socket", "virtproxyd-tls.socket"])
        self.assertTrue(any("migration" in error for error in errors))
        self.assertTrue(any("listener" in error for error in errors))
        self.put("/etc/polkit-1/rules.d/20-personal.rules", 'action.id == "org.libvirt.unix.manage"')
        self.put("/etc/group", "libvirt:x:999:someone\n")
        self.assertTrue(any("authorization" in error for error in self.conflicts(result)))
        self.assertTrue(any("group members" in error for error in self.conflicts(result)))

    def test_arm_does_not_install_all_architecture_registrations(self):
        result = plan("--profile", "custom", "--include", "containers-arm")
        self.assertNotIn("qemu-user-static-binfmt", result["packages"])
        self.put("/usr/lib/binfmt.d/qemu-ppc.conf", "qemu-ppc-static")
        self.assertTrue(any("binfmt" in error for error in self.conflicts(result)))


class LauncherTests(unittest.TestCase):
    def test_xdg_precedence_visibility_and_nested_ids(self):
        with tempfile.TemporaryDirectory() as directory:
            user, system = Path(directory) / "user", Path(directory) / "system"
            user.mkdir()
            system.mkdir()
            for name, attributes in {
                "hidden.desktop": "Hidden=true\n", "background.desktop": "NoDisplay=true\n",
                "gnome.desktop": "OnlyShowIn=GNOME;\n", "niri.desktop": "NotShowIn=GNOME;\n",
                "override.desktop": "", "user.desktop": "",
            }.items():
                (system / name).write_text("[Desktop Entry]\nType=Application\n" + attributes)
            (user / "override.desktop").write_text("[Desktop Entry]\nHidden=true\n")
            (system / "nested").mkdir()
            (system / "nested/app.desktop").write_text("[Desktop Entry]\nType=Application\n")
            result = cachyos.launcher_inventory(["gnome.desktop", "missing.desktop"], [user, system])
            self.assertEqual(result["missing"], ["missing.desktop"])
            self.assertEqual(result["unexpected"], ["nested-app.desktop", "user.desktop"])
            self.assertFalse(result["entries"]["override.desktop"]["visible"])
            self.assertEqual(result["entries"]["override.desktop"]["path"], str(user / "override.desktop"))
            niri = cachyos.launcher_inventory(["niri.desktop"], [user, system], "niri")
            self.assertEqual(niri["missing"], [])
            self.assertFalse(niri["entries"]["gnome.desktop"]["visible"])
            self.assertTrue((user / "override.desktop").exists())


class SafetyTests(unittest.TestCase):
    def test_changed_reviewed_plan_is_refused_before_package_transactions(self):
        args = cachyos.parser().parse_args(["apply", "--profile", "custom", "--confirm", "--recovery-record", __file__, "--reviewed-plan-hash", "changed"])
        with tempfile.TemporaryDirectory() as directory, patch.object(cachyos, "STATE", Path(directory)), \
                patch.object(cachyos.os, "geteuid", return_value=0), patch.object(cachyos, "target_check"), \
                patch.object(cachyos, "recovery_check"), patch.object(cachyos, "conflicts", return_value=[]), \
                patch.object(cachyos, "repository_check", return_value={}), patch.object(cachyos, "mutate") as mutate:
            with self.assertRaisesRegex(cachyos.Refusal, "changed since the reviewed plan"):
                cachyos.apply(args, plan("--profile", "custom"))
            mutate.assert_not_called()

    def test_enablement_verifies_next_boot_not_just_an_active_process(self):
        result = plan("--profile", "desktop")
        def status(*args, **kwargs):
            return "graphical.target" if "get-default" in args else "enabled"
        with patch.object(cachyos, "run", side_effect=status):
            self.assertEqual(cachyos.enablement_problems(result), [])
        with patch.object(cachyos, "run", return_value="disabled"):
            problems = cachyos.enablement_problems(result)
            self.assertTrue(any("next boot" in item for item in problems))
            self.assertTrue(any("global user" in item for item in problems))

    def test_managed_writes_reapply_without_overwriting_changes(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "managed.conf"
            result = {"modules": [], "system_units": [], "files": {
                str(path): {"content": "managed\n", "sha256": cachyos.digest(b"managed\n")}
            }}
            cachyos.write_managed(result)
            before = path.stat().st_mtime_ns
            cachyos.write_managed(result)
            self.assertEqual(path.stat().st_mtime_ns, before)
            path.write_text("user edited\n")
            with self.assertRaises(cachyos.Refusal):
                cachyos.write_managed(result)
            self.assertEqual(path.read_text(), "user edited\n")

    def test_state_files_are_private(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "state.json"
            cachyos.save(path, {"test": True})
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(json.loads(path.read_text()), {"test": True})

    def test_default_command_is_read_only(self):
        with patch.object(cachyos, "detect", return_value=HARDWARE), patch.object(cachyos, "conflicts", return_value=[]), patch.object(cachyos, "mutate") as mutate, patch.object(cachyos, "save") as save, redirect_stdout(io.StringIO()) as output:
            self.assertEqual(cachyos.main([]), 0)
            self.assertEqual(json.loads(output.getvalue())["profile"], "workstation")
            mutate.assert_not_called()
            save.assert_not_called()

    def test_apply_requires_root_and_explicit_confirmation(self):
        args = cachyos.parser().parse_args(["apply"])
        with patch.object(cachyos.os, "geteuid", return_value=1000), self.assertRaisesRegex(cachyos.Refusal, "root"):
            cachyos.apply(args, plan())
        with patch.object(cachyos.os, "geteuid", return_value=0), self.assertRaisesRegex(cachyos.Refusal, "confirm"):
            cachyos.apply(args, plan())

    def test_non_cachyos_is_refused(self):
        with patch.object(cachyos, "read", return_value="ID=fedora\n"), self.assertRaisesRegex(cachyos.Refusal, "CachyOS"):
            cachyos.target_check(plan())

    def test_repository_signature_verification_cannot_be_weakened(self):
        for policy in ("Never", "PackageOptional", "PackageRequired PackageTrustAll", "Required TrustAll"):
            def fake_run(*args, **kwargs):
                if "--repo-list" in args:
                    return "cachyos\ncore\nextra"
                if "SigLevel" in args:
                    return policy
                return "package data"
            with self.subTest(policy=policy), patch.object(cachyos, "run", side_effect=fake_run), self.assertRaises(cachyos.Refusal):
                cachyos.repository_check(["niri"])

    def test_repository_check_reads_without_partial_sync(self):
        calls = []
        def fake_run(*args, **kwargs):
            calls.append(args)
            if "--repo-list" in args:
                return "cachyos\ncore"
            if "SigLevel" in args:
                return "PackageRequired PackageTrustedOnly DatabaseOptional DatabaseTrustedOnly"
            return "package data"
        with patch.object(cachyos, "run", side_effect=fake_run):
            cachyos.repository_check(["niri"])
        self.assertIn(("pacman", "-Si", "niri"), calls)
        self.assertNotIn("-Sy", sum((list(call) for call in calls), []))

    def test_repository_check_inherits_global_signature_policy(self):
        policy = "PackageRequired\nPackageTrustedOnly\nDatabaseOptional\nDatabaseTrustedOnly"
        def fake_run(*args, **kwargs):
            if "--repo-list" in args:
                return "cachyos-znver4\ncachyos-core-znver4\ncore\nextra"
            if "SigLevel" in args:
                return "" if "--repo" in args else policy
            return "package data"
        with patch.object(cachyos, "run", side_effect=fake_run):
            provenance = cachyos.repository_check(["niri"])
        self.assertEqual(provenance["signature_policy"]["cachyos-znver4"], "")
        for repo in provenance["repositories"]:
            self.assertEqual(provenance["effective_signature_policy"][repo], policy)

    def test_repository_check_does_not_replace_unsafe_repo_overrides(self):
        for policy in ("Never", "Optional", "PackageOptional", "Required TrustAll",
                       "PackageRequired PackageTrustAll"):
            def fake_run(*args, **kwargs):
                if "--repo-list" in args:
                    return "cachyos-znver4\ncore"
                if "SigLevel" in args:
                    return policy if "--repo" in args else "Required DatabaseOptional"
                self.fail("Unsafe policy must fail before querying package transactions")
            with self.subTest(policy=policy), patch.object(cachyos, "run", side_effect=fake_run):
                with self.assertRaisesRegex(cachyos.Refusal, "cachyos-znver4"):
                    cachyos.repository_check(["niri"])

    def test_repository_check_rejects_empty_or_unsafe_global_policy(self):
        for policy in ("", "Never", "Optional TrustAll"):
            def fake_run(*args, **kwargs):
                if "--repo-list" in args:
                    return "cachyos-znver4\ncore"
                if "SigLevel" in args:
                    return "" if "--repo" in args else policy
                self.fail("Unsafe policy must fail before querying package transactions")
            with self.subTest(policy=policy), patch.object(cachyos, "run", side_effect=fake_run):
                with self.assertRaisesRegex(cachyos.Refusal, "global"):
                    cachyos.repository_check(["niri"])

    def test_repository_query_failure_is_not_treated_as_inheritance(self):
        def fake_run(*args, **kwargs):
            if "--repo-list" in args:
                return "cachyos-znver4\ncore"
            if args == ("pacman-conf", "SigLevel"):
                return "Required DatabaseOptional"
            if "--repo" in args:
                raise cachyos.Refusal("pacman-conf: could not read configuration")
            self.fail("Failed query must stop preflight")
        with patch.object(cachyos, "run", side_effect=fake_run):
            with self.assertRaisesRegex(cachyos.Refusal, "could not read configuration"):
                cachyos.repository_check(["niri"])

    def test_gdm_only_initializes_accounts_without_any_saved_session(self):
        for prop in ("Session", "XSession", "SessionType"):
            with self.subTest(prop=prop), patch.object(cachyos, "account_path", return_value="/user"), patch.object(cachyos, "run", side_effect=lambda *args: 's "gnome"' if args[-1] == prop else 's ""'), patch.object(cachyos, "mutate") as mutate, redirect_stdout(io.StringIO()):
                cachyos.initial_session("person")
                mutate.assert_not_called()
        with patch.object(cachyos, "account_path", return_value="/user"), patch.object(cachyos, "run", return_value='s ""'), patch.object(cachyos, "mutate") as mutate:
            cachyos.initial_session("person")
            self.assertEqual([call.args[-3:] for call in mutate.call_args_list], [("SetSession", "s", "niri"), ("SetSessionType", "s", "wayland")])

    def test_recovery_requires_recorded_passing_tests(self):
        record = json.loads((cachyos.DATA / "recovery.example.json").read_text())
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "recovery.json"
            path.write_text(json.dumps(record))
            with self.assertRaises(cachyos.Refusal):
                cachyos.recovery_check(str(path))
            record.update(external_backup_confirmed=True, backup_location="external disk")
            record["target"] = {field: "reviewed" for field in record["target"]}
            for field, value in record.items():
                if field.endswith("_test"):
                    value.update(date="2026-10-28", result="passed", details="Actual test record")
            path.write_text(json.dumps(record))
            self.assertEqual(cachyos.recovery_check(str(path)), record)

    def test_apply_orders_full_upgrade_inventory_and_selected_enablement(self):
        args = cachyos.parser().parse_args(["apply", "--profile", "custom", "--include", "flatpak-user", "--confirm", "--recovery-record", __file__])
        result = plan("--profile", "custom", "--include", "flatpak-user")
        events = []
        with tempfile.TemporaryDirectory() as directory, patch.object(cachyos, "STATE", Path(directory)), patch.object(cachyos.os, "geteuid", return_value=0), patch.object(cachyos, "target_check"), patch.object(cachyos, "recovery_check"), patch.object(cachyos, "conflicts", return_value=[]), patch.object(cachyos, "repository_check", return_value={}), patch.object(cachyos, "inventory", return_value={}), patch.object(cachyos, "enablement_problems", return_value=[]), patch.object(cachyos, "write_managed", side_effect=lambda p: events.append("files")), patch.object(cachyos, "content_checks", side_effect=lambda *a, **k: events.append("checks")), patch.object(cachyos, "mutate", side_effect=lambda *a: events.append(a)), redirect_stdout(io.StringIO()):
            cachyos.apply(args, result)
            self.assertEqual(events[:2], [("pacman", "-Syu"), ("pacman", "-S", "--needed", *result["packages"])])
            self.assertTrue((Path(directory) / "current.json").exists())
            self.assertTrue(list(Path(directory).glob("runs/*/before.json")))
            self.assertTrue(list(Path(directory).glob("runs/*/after.json")))
            commands = [event for event in events if isinstance(event, tuple)]
            self.assertFalse(any("--now" in command or "reboot" in command for command in commands))
            self.assertIn(("systemctl", "enable", "gdm.service"), commands)
            self.assertIn(("systemctl", "--global", "enable", *result["global_user_units"]), commands)
            self.assertFalse(any(command[0] == "flatpak" or "start" in command for command in commands))
            self.assertFalse(any("tailscaled.service" in command for command in commands))

    def test_failed_apply_records_partial_state_without_rollback(self):
        args = cachyos.parser().parse_args(["apply", "--profile", "custom", "--confirm", "--recovery-record", __file__])
        result = plan("--profile", "custom")
        with tempfile.TemporaryDirectory() as directory, patch.object(cachyos, "STATE", Path(directory)), patch.object(cachyos.os, "geteuid", return_value=0), patch.object(cachyos, "target_check"), patch.object(cachyos, "recovery_check"), patch.object(cachyos, "conflicts", return_value=[]), patch.object(cachyos, "repository_check", return_value={}), patch.object(cachyos, "inventory", return_value={}), patch.object(cachyos, "mutate", side_effect=cachyos.Refusal("test transaction failed")) as mutate:
            current = Path(directory) / "current.json"
            current.write_text('{"previous": true}\n')
            with self.assertRaisesRegex(cachyos.Refusal, "transaction failed"):
                cachyos.apply(args, result)
            self.assertEqual(json.loads(current.read_text()), {"previous": True})
            self.assertTrue(list(Path(directory).glob("runs/*/after.json")))
            status = json.loads(next(Path(directory).glob("runs/*/result.json")).read_text())
            self.assertIn("incomplete", status["status"])
            self.assertEqual(mutate.call_count, 1)


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        directory = self.stack.enter_context(tempfile.TemporaryDirectory())
        self.root = Path(directory)
        self.calls = []
        self.recovery = self.root / "provided-recovery.json"
        self.recovery.write_text("{}\n")
        self.stack.enter_context(patch.dict(os.environ, {"XDG_STATE_HOME": str(self.root)}))
        self.stack.enter_context(patch.object(cachyos.os, "geteuid", return_value=1000))
        self.stack.enter_context(patch.object(cachyos.sys, "stdin", SimpleNamespace(isatty=lambda: True)))
        self.stack.enter_context(patch.object(cachyos.pwd, "getpwuid", return_value=SimpleNamespace(pw_name="tester")))
        self.stack.enter_context(patch.object(cachyos, "detect", return_value=HARDWARE))
        self.stack.enter_context(patch.object(cachyos, "target_check"))
        self.enabled = self.stack.enter_context(patch.object(cachyos, "enabled", return_value=False))
        self.stack.enter_context(patch.object(cachyos, "wifi_backends", return_value={}))
        self.stack.enter_context(patch.object(cachyos, "zram_sources", return_value=[]))
        self.stack.enter_context(patch.object(cachyos, "run", return_value=""))
        self.stack.enter_context(patch.object(cachyos, "recovery_check"))
        self.wizard = self.stack.enter_context(patch.object(cachyos, "recovery_wizard", return_value=str(self.recovery)))
        self.input = self.stack.enter_context(patch("builtins.input", return_value="INSTALL"))
        self.subprocess = self.stack.enter_context(patch.object(cachyos.subprocess, "run", side_effect=self.command))
        self.output = self.stack.enter_context(redirect_stdout(io.StringIO()))
        self.preflight_conflicts = []

    def command(self, command, **kwargs):
        self.calls.append(command)
        if command[3] == "plan":
            args = cachyos.parser().parse_args(command[3:])
            result = cachyos.build_plan(args, HARDWARE)
            result["existing_conflicts"] = self.preflight_conflicts
            return SimpleNamespace(returncode=0, stdout=json.dumps(result))
        self.assertEqual(command[3], "apply")
        return SimpleNamespace(returncode=0)

    def test_single_entrypoint_reviews_then_applies_fixed_workstation(self):
        cachyos.setup(cachyos.parser().parse_args(["setup"]))
        self.assertEqual([call[3] for call in self.calls], ["plan", "apply"])
        for call in self.calls:
            self.assertEqual(call[0], "sudo")
            self.assertEqual(call[call.index("--profile") + 1], "workstation")
            self.assertEqual(call[call.index("--initial-user") + 1], "tester")
            self.assertNotIn("--noconfirm", call)
        self.assertIn("--confirm", self.calls[-1])
        self.assertIn(str(self.recovery), self.calls[-1])
        self.assertTrue(list(self.root.glob("cachyos-desktop/plan-*.json")))
        self.wizard.assert_called_once()
        self.assertNotIn("make local", " ".join(self.calls[-1]))

    def test_setup_preserves_detected_firewall_and_power_stack(self):
        self.enabled.side_effect = lambda unit: unit in {"ufw.service", "power-profiles-daemon.service"}
        cachyos.setup(cachyos.parser().parse_args(["setup"]))
        command = self.calls[-1]
        self.assertEqual(command[command.index("--firewall") + 1], "ufw")
        self.assertEqual(command[command.index("--power") + 1], "existing")
        self.assertNotIn("--without", command)
        applied = cachyos.build_plan(cachyos.parser().parse_args(command[3:]), HARDWARE)
        self.assertIn("tailscaled.service", applied["system_units"])
        self.assertIn("virtualization-3d", applied["modules"])
        self.assertIn("containers-arm", applied["modules"])

    def test_setup_does_not_expose_feature_selection(self):
        for flags in (("--profile", "desktop"), ("--without", "tailscale"),
                      ("--include", "virtualization-3d"), ("--libvirt-proxy",)):
            with self.subTest(flags=flags), self.assertRaisesRegex(cachyos.Refusal, "fixed workstation"):
                cachyos.setup(cachyos.parser().parse_args(["setup", *flags]))
        self.subprocess.assert_not_called()

    def test_rejected_plan_does_not_install_or_request_recovery_details(self):
        self.input.return_value = "cancel"
        with self.assertRaisesRegex(cachyos.Refusal, "cancelled"):
            cachyos.setup(cachyos.parser().parse_args(["setup", "--recovery-record", str(self.recovery)]))
        self.assertEqual([call[3] for call in self.calls], ["plan"])
        self.wizard.assert_not_called()

    def test_preflight_conflict_does_not_install(self):
        self.preflight_conflicts = ["Existing configuration needs review"]
        with self.assertRaisesRegex(cachyos.Refusal, "needs review"):
            cachyos.setup(cachyos.parser().parse_args(["setup"]))
        self.assertEqual([call[3] for call in self.calls], ["plan"])
        self.wizard.assert_not_called()

    def test_failed_repository_review_never_attempts_installation(self):
        self.subprocess.side_effect = None
        self.subprocess.return_value = SimpleNamespace(returncode=1)
        with self.assertRaisesRegex(cachyos.Refusal, "Pre-install review failed"):
            cachyos.setup(cachyos.parser().parse_args(["setup"]))
        self.subprocess.assert_called_once()
        self.assertEqual(self.subprocess.call_args.args[0][3], "plan")
        self.wizard.assert_not_called()
        self.input.assert_not_called()

    def test_root_and_noninteractive_setup_cannot_install(self):
        with patch.object(cachyos.os, "geteuid", return_value=0), self.assertRaisesRegex(cachyos.Refusal, "normal user"):
            cachyos.setup(cachyos.parser().parse_args(["setup"]))
        with patch.object(cachyos.sys, "stdin", SimpleNamespace(isatty=lambda: False)), self.assertRaisesRegex(cachyos.Refusal, "interactive"):
            cachyos.setup(cachyos.parser().parse_args(["setup"]))
        self.subprocess.assert_not_called()


class RecoveryWizardTests(unittest.TestCase):
    def answers(self, date="2026-10-28"):
        return ["external USB backup", *[f"{date} Actual successful {test} test" for test in ("restore", "rescue", "fallback", "initramfs")], "systemd-boot", "mkinitcpio", "btrfs"]

    def test_wizard_records_user_evidence_without_a_handwritten_json_file(self):
        with tempfile.TemporaryDirectory() as directory, patch("builtins.input", side_effect=self.answers()), patch.object(cachyos, "run", return_value=""), patch.object(cachyos.shutil, "which", return_value=None), redirect_stdout(io.StringIO()):
            destination = Path(directory) / "recovery.json"
            self.assertEqual(cachyos.recovery_wizard(destination, HARDWARE), str(destination))
            record = cachyos.recovery_check(str(destination))
            self.assertEqual(record["backup_restore_test"]["date"], "2026-10-28")
            self.assertIn("Actual successful", record["backup_restore_test"]["details"])
            self.assertEqual(destination.stat().st_mode & 0o777, 0o600)

    def test_invalid_evidence_never_saves_a_passing_record(self):
        with tempfile.TemporaryDirectory() as directory, patch("builtins.input", side_effect=self.answers("invalid-date")), patch.object(cachyos, "run", return_value=""), patch.object(cachyos.shutil, "which", return_value=None), redirect_stdout(io.StringIO()):
            destination = Path(directory) / "recovery.json"
            with self.assertRaises(cachyos.Refusal):
                cachyos.recovery_wizard(destination, HARDWARE)
            self.assertFalse(destination.exists())


if __name__ == "__main__":
    unittest.main()
