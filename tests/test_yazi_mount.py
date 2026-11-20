"""Yazi mounts USB disks (mount.yazi) and SMB shares (yazi-smb + GVfs) without system changes."""

import os
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
YAZI = ROOT / "packages/yazi/.config/yazi"
SMB = ROOT / "packages/yazi/.local/bin/yazi-smb"


class KeymapAndPluginTests(unittest.TestCase):
    def test_keys_open_the_mount_manager_and_the_smb_helper(self):
        keymap = tomllib.loads((YAZI / "keymap.toml").read_text())["mgr"]["prepend_keymap"]
        by_key = {tuple(k["on"]) if isinstance(k["on"], list) else k["on"]: k["run"] for k in keymap}
        self.assertEqual(by_key["M"], "plugin mount")
        self.assertIn("yazi-smb", by_key[("g", "s")])
        self.assertIn("mount", by_key[("g", "s")])
        self.assertIn("--block", by_key[("g", "s")], "gio may ask for credentials on the terminal")
        self.assertIn("unmount", by_key[("g", "u")])

    def test_mount_plugin_is_vendored_and_pinned(self):
        plugin = YAZI / "plugins/mount.yazi"
        for name in ("main.lua", "cross.lua", "sudo.lua", "LICENSE"):
            self.assertTrue((plugin / name).is_file(), name)
        package = tomllib.loads((YAZI / "package.toml").read_text())
        deps = {d["use"]: d for d in package["plugin"]["deps"]}
        pin = deps["yazi-rs/plugins:mount"]
        self.assertRegex(pin["rev"], r"^[0-9a-f]{7,}$")
        self.assertRegex(pin["hash"], r"^[0-9a-f]{32}$")

    def test_no_system_changes_are_needed(self):
        # The image already ships udisks2, gvfs-smb and gvfs-fuse; nothing here installs software.
        text = (YAZI / "keymap.toml").read_text() + SMB.read_text()
        for forbidden in ("rpm-ostree", "dnf ", "sudo ", "mount -t cifs"):
            self.assertNotIn(forbidden, text)


class YaziSmbTests(unittest.TestCase):
    """Run the real script against fake `gio` and `ya` programs that record their calls."""

    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.share = self.root / "gvfs/smb-share:server=server,share=share"
        self.share.mkdir(parents=True)
        self.log = self.root / "calls"
        self.state = self.root / "mounted"
        stubs = self.root / "bin"
        stubs.mkdir()
        gio = stubs / "gio"
        gio.write_text(f"""#!/bin/bash
echo "gio $*" >> '{self.log}'
case $1 in
  info) [[ -e '{self.state}' ]] || exit 1; echo "local path: {self.share}" ;;
  mount) case $2 in
           -l) [[ -e '{self.state}' ]] && cat '{self.root}/listing'; exit 0 ;;
           -u) rm -f '{self.state}'; exit "${{GIO_UNMOUNT_STATUS:-0}}" ;;
           *) [[ ${{GIO_MOUNT_FAILS:-}} ]] && exit 1; touch '{self.state}' ;;
         esac ;;
esac
""")
        ya = stubs / "ya"
        ya.write_text(f'#!/bin/bash\necho "ya $*" >> \'{self.log}\'\n')
        for program in (gio, ya):
            program.chmod(0o755)
        (self.root / "listing").write_text("Mount(0): share on server -> smb://server/share/\n")
        self.env = {**os.environ, "PATH": f"{stubs}:{os.environ['PATH']}", "YAZI_ID": "42",
                    "HOME": str(self.root / "home")}

    def run_script(self, *args, **env):
        return subprocess.run(["bash", str(SMB), *args], env={**self.env, **env}, text=True,
                              capture_output=True, stdin=subprocess.DEVNULL)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_mounts_and_tells_the_running_yazi_to_enter_the_share(self):
        result = self.run_script("mount", "//server/share")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["gio info smb://server/share", "gio mount smb://server/share",
                                        "gio info smb://server/share", f"ya emit-to 42 cd {self.share}"])

    def test_address_forms_are_normalized(self):
        for form in ("server/share", "//server/share", "smb://server/share", r"\\server\share",
                     "  smb://server/share/  "):
            with self.subTest(form=form):
                self.state.unlink(missing_ok=True)
                self.log.unlink(missing_ok=True)
                result = self.run_script("mount", form)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("gio mount smb://server/share", self.calls())

    def test_already_mounted_share_is_not_mounted_again(self):
        self.state.touch()
        self.assertEqual(self.run_script("mount", "server/share").returncode, 0)
        self.assertNotIn("gio mount smb://server/share", self.calls())
        self.assertIn(f"ya emit-to 42 cd {self.share}", self.calls())

    def test_outside_yazi_the_path_is_printed_instead(self):
        env = {k: v for k, v in self.env.items() if k != "YAZI_ID"}
        result = subprocess.run(["bash", str(SMB), "mount", "server/share"], env=env, text=True,
                                capture_output=True, stdin=subprocess.DEVNULL)
        self.assertEqual(result.stdout.strip(), str(self.share))
        self.assertFalse([c for c in self.calls() if c.startswith("ya ")])

    def test_malformed_servers_never_reach_gio(self):
        for bad in ("", "-o evil", "file:///etc", "bad host/share", "$(id)/x", ";id/share", "--help"):
            with self.subTest(address=bad):
                self.log.unlink(missing_ok=True)
                result = self.run_script("mount", bad)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse([c for c in self.calls() if c.startswith("gio mount")])

    def test_shell_metacharacters_in_the_share_name_are_never_executed(self):
        marker = self.root / "executed"
        for share in (f"server/a; touch {marker}", f"server/$(touch {marker})", f"server/`touch {marker}`"):
            with self.subTest(share=share):
                self.run_script("mount", share)
                self.assertFalse(marker.exists())
                self.log.unlink(missing_ok=True)

    def test_failed_mount_reports_and_does_not_move_yazi(self):
        result = self.run_script("mount", "server/share", GIO_MOUNT_FAILS="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not mount", result.stderr)
        self.assertFalse([c for c in self.calls() if c.startswith("ya ")])

    def test_unmount_sends_yazi_home_so_it_is_not_left_in_a_dead_directory(self):
        self.state.touch()
        result = self.run_script("unmount")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("gio mount -u smb://server/share", self.calls())
        self.assertIn(f"ya emit-to 42 cd {self.root / 'home'}", self.calls())

    def test_unmount_without_mounts_or_when_busy_fails_clearly(self):
        result = self.run_script("unmount")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no SMB shares", result.stderr)
        self.state.touch()
        result = self.run_script("unmount", GIO_UNMOUNT_STATUS="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not unmount", result.stderr)

    def test_unknown_command_prints_usage(self):
        result = self.run_script("explode")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("usage", result.stderr)


if __name__ == "__main__":
    unittest.main()
