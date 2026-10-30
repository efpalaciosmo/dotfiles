"""Read-only integration with the real pacman-conf parser; no package operations."""

import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("repository_installer", ROOT / "scripts/cachyos.py")
installer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(installer)
PACMAN_CONF = shutil.which("pacman-conf")
REPOSITORIES = ("cachyos-znver4", "cachyos-core-znver4", "cachyos-extra-znver4",
                "cachyos", "core", "extra")


@unittest.skipUnless(PACMAN_CONF, "requires native pacman-conf (run in an Arch/CachyOS test environment)")
class NativeRepositoryPolicyTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.config = self.root / "pacman.conf"
        self.calls = []
        native_run = installer.run

        def query(*args, **kwargs):
            self.calls.append(args)
            if args[0] == "pacman-conf":
                return native_run(PACMAN_CONF, "--config", str(self.config), *args[1:], **kwargs)
            # Only metadata/transaction estimates are stubbed, never signature parsing.
            if args[:2] in (("pacman", "-Si"), ("pacman", "-Sp"),
                            ("pacman", "-Sup"), ("pacman", "-Qm")):
                return "fixture package metadata"
            self.fail(f"Unexpected command: {args}")

        patched = patch.object(installer, "run", side_effect=query)
        patched.start()
        self.addCleanup(patched.stop)

    def configure(self, global_policy="Required DatabaseOptional", overrides=None):
        mirror = self.root / "mirrorlist"
        mirror.write_text("Server = https://mirror.example.invalid/$repo/$arch\n")
        repositories = self.root / "repositories.conf"
        repositories.write_text("".join(
            f"[{repo}]\n" + (f"SigLevel = {overrides[repo]}\n" if overrides and repo in overrides else "")
            + f"Include = {mirror}\n" for repo in REPOSITORIES))
        self.config.write_text("[options]\nArchitecture = x86_64\n"
                               f"SigLevel = {global_policy}\nInclude = {repositories}\n")

    def test_real_parser_reports_empty_inherited_policy_and_preflight_accepts_it(self):
        self.configure()
        provenance = installer.repository_check(["niri"])
        global_policy = provenance["signature_policy"]["global"]
        self.assertIn("PackageRequired", global_policy.split())
        self.assertIn("PackageTrustedOnly", global_policy.split())
        self.assertEqual(provenance["repositories"], list(REPOSITORIES))
        for repo in REPOSITORIES:
            self.assertEqual(provenance["signature_policy"][repo], "")
            self.assertEqual(provenance["effective_signature_policy"][repo], global_policy)
            self.assertIn(f"/{repo}/x86_64", provenance["servers"][repo])
        self.assertFalse(any("-Sy" in call or "-Syu" in call for call in self.calls))

    def test_database_only_override_keeps_required_trusted_package_signatures(self):
        self.configure(overrides={"cachyos-znver4": "DatabaseRequired"})
        provenance = installer.repository_check(["niri"])
        policy = provenance["effective_signature_policy"]["cachyos-znver4"].split()
        self.assertIn("PackageRequired", policy)
        self.assertIn("PackageTrustedOnly", policy)
        self.assertIn("DatabaseRequired", policy)

    def test_real_parser_unsafe_overrides_are_not_replaced_with_global_policy(self):
        for policy in ("Never", "Optional", "PackageOptional", "TrustAll",
                       "PackageRequired PackageTrustAll"):
            with self.subTest(policy=policy):
                self.configure(overrides={"cachyos-znver4": policy})
                with self.assertRaisesRegex(installer.Refusal, "cachyos-znver4"):
                    installer.repository_check(["niri"])
        self.assertTrue(all(call[0] == "pacman-conf" for call in self.calls))

    def test_real_parser_insecure_global_policy_cannot_be_inherited(self):
        self.configure(global_policy="Optional TrustAll")
        with self.assertRaisesRegex(installer.Refusal, "global"):
            installer.repository_check(["niri"])
        self.assertTrue(all(call[0] == "pacman-conf" for call in self.calls))

    def test_real_parser_failure_does_not_fall_back_to_global_policy(self):
        self.config.write_text("[options]\nSigLevel = NotAValidPolicy\n")
        with self.assertRaisesRegex(installer.Refusal, "invalid value"):
            installer.repository_check(["niri"])
        self.assertTrue(all(call[0] == "pacman-conf" for call in self.calls))


if __name__ == "__main__":
    unittest.main()
