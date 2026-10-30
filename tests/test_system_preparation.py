"""Locale and rootless-ID preparation without touching /etc or real accounts."""

import importlib.util
import tempfile
import unittest
from contextlib import ExitStack
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("cachyos_preparation", ROOT / "scripts/cachyos.py")
cachyos = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(cachyos)


class PreparationTests(unittest.TestCase):
    def setUp(self):
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        self.root = Path(self.stack.enter_context(tempfile.TemporaryDirectory()))
        self.plan = {"modules": ["niri", "containers"], "system_preparation": {
            "locale": "en_US.UTF-8", "rootless_user": "tester",
        }}
        self.account = SimpleNamespace(pw_uid=1000, pw_gid=1000)
        self.stack.enter_context(patch.object(cachyos.pwd, "getpwnam", return_value=self.account))
        self.stack.enter_context(patch.object(cachyos.pwd, "getpwall", return_value=[self.account]))
        self.stack.enter_context(patch.object(cachyos.grp, "getgrall", return_value=[]))
        self.run = self.stack.enter_context(patch.object(cachyos, "run", return_value="en_US.utf8\nC"))

    def put(self, target, text):
        path = self.root / target.lstrip("/")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def preview(self):
        return cachyos.preparation_plan(self.plan, self.root)

    def test_preview_preserves_locales_and_allocates_a_free_common_range(self):
        self.put("/etc/locale.gen", "es_ES.UTF-8 UTF-8\n#en_US.UTF-8 UTF-8\n")
        self.put("/etc/subuid", "other:100000:65536\n")
        self.put("/etc/subgid", "other:200000:65536\n")
        preview = self.preview()
        self.assertEqual(preview["files"]["/etc/locale.gen"]["after"], "es_ES.UTF-8 UTF-8\nen_US.UTF-8 UTF-8\n")
        self.assertEqual(preview["files"]["/etc/subuid"]["after"], "other:100000:65536\ntester:265536:65536\n")
        self.assertEqual(preview["files"]["/etc/subgid"]["after"], "other:200000:65536\ntester:265536:65536\n")
        self.assertTrue(preview["generate_locale"])
        self.assertIn("#en_US", (self.root / "etc/locale.gen").read_text())

    def test_existing_valid_name_or_numeric_ranges_are_preserved(self):
        self.put("/etc/locale.gen", "en_US.UTF-8 UTF-8\n")
        self.put("/etc/subuid", "tester:300000:65536\n")
        self.put("/etc/subgid", "1000:400000:65536\n")
        self.assertEqual(self.preview(), {"files": {}, "generate_locale": False})

    def test_enabled_but_ungenerated_locale_is_generated(self):
        self.put("/etc/locale.gen", "en_US.UTF-8 UTF-8\n")
        self.run.return_value = "C\nC.utf8"
        self.assertTrue(self.preview()["generate_locale"])

    def test_bad_overlapping_or_undersized_ranges_are_not_rewritten(self):
        for text in ("bad entry\n", "one:100000:65536\ntwo:120000:65536\n",
                     "tester:100000:1000\n", "other:1000:65536\n", "other:4294967295:65536\n"):
            with self.subTest(text=text):
                path = self.put("/etc/subuid", text)
                with self.assertRaises(cachyos.Refusal):
                    self.preview()
                self.assertEqual(path.read_text(), text)

    def test_symlinked_configuration_is_refused(self):
        source = self.put("outside", "personal data")
        (self.root / "etc").mkdir()
        (self.root / "etc/locale.gen").symlink_to(source)
        with self.assertRaisesRegex(cachyos.Refusal, "symlink"):
            self.preview()
        self.assertEqual(source.read_text(), "personal data")

    def local_preparation(self):
        preparation = self.preview()
        preparation["files"] = {str(self.root / target.lstrip("/")): value
                                for target, value in preparation["files"].items()}
        return preparation

    def test_apply_preserves_modes_records_changes_and_is_idempotent(self):
        path = self.put("/etc/locale.gen", "#en_US.UTF-8 UTF-8\n")
        path.chmod(0o640)
        preparation = self.local_preparation()
        with patch.object(cachyos, "mutate") as mutate:
            cachyos.apply_preparation(preparation, self.root / "record")
        mutate.assert_called_once_with("locale-gen")
        self.assertEqual(path.stat().st_mode & 0o777, 0o640)
        self.assertTrue((self.root / "record/system-preparation.json").exists())
        self.assertEqual(self.preview(), {"files": {}, "generate_locale": False})

    def test_changed_files_abort_before_any_preparation_write(self):
        preparation = self.local_preparation()
        self.put("/etc/subgid", "new-owner:300000:65536\n")
        with self.assertRaisesRegex(cachyos.Refusal, "changed since review"):
            cachyos.apply_preparation(preparation, self.root / "record")
        self.assertFalse((self.root / "etc/locale.gen").exists())
        self.assertFalse((self.root / "etc/subuid").exists())

    def test_unprivileged_and_missing_accounts_cannot_be_provisioned(self):
        self.account.pw_uid = 0
        with self.assertRaisesRegex(cachyos.Refusal, "regular local account"):
            self.preview()
        self.plan["system_preparation"]["rootless_user"] = None
        with self.assertRaisesRegex(cachyos.Refusal, "initial-user"):
            self.preview()
