"""File picker regressions: no directories, external links or cache entries."""

from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[1] / "packages/fuzzel/.config/fuzzel/scripts/picker"
spec = spec_from_loader("fuzzel_picker", SourceFileLoader("fuzzel_picker", str(SOURCE)))
picker = module_from_spec(spec)
spec.loader.exec_module(picker)


class PickerTests(unittest.TestCase):
    def test_search_lists_only_home_files_without_cache_or_external_links(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            home = base / "home"
            home.mkdir()
            (home / "Documents").mkdir()
            (home / "Documents" / "test.txt").write_text("test")
            (home / ".config").mkdir()
            (home / ".config" / "settings.ini").write_text("test")
            (home / ".cache").mkdir()
            (home / ".cache" / "cached.txt").write_text("test")
            outside = base / "outside.txt"
            outside.write_text("test")
            (home / "external.txt").symlink_to(outside)

            self.assertEqual(
                {p.relative_to(home).as_posix() for p in picker.home_files(home)},
                {"Documents/test.txt", ".config/settings.ini"},
            )
            with patch.object(picker.Path, "home", return_value=home), \
                    patch.object(picker, "choose", return_value=0) as choose, \
                    patch.object(picker, "open_path") as open_path:
                self.assertEqual(picker.recursive(), 0)
                self.assertEqual(choose.call_args.args[1],
                                 ["settings.ini  ·  .config", "test.txt  ·  Documents"])
                open_path.assert_called_once_with(home / ".config/settings.ini")

    def test_browser_stays_inside_home(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            home = base / "home"
            home.mkdir()
            (home / "folder").mkdir()
            (home / "link").symlink_to(base, target_is_directory=True)
            with patch.object(picker.Path, "home", return_value=home), \
                    patch.object(picker, "choose", side_effect=[0, 0, None]) as choose, \
                    patch.object(picker, "open_path") as open_path:
                self.assertEqual(picker.browse(), 0)
                self.assertEqual(choose.call_args_list[0].args[1], ["folder/"])
                self.assertEqual(choose.call_args_list[1].args[1],
                                 ["..  Volver"])
                open_path.assert_not_called()


if __name__ == "__main__":
    unittest.main()
