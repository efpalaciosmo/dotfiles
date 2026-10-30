"""Desktop session integration remains managed by personal dotfiles."""

import configparser
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class SessionConfigTests(unittest.TestCase):
    def test_portals_route_to_the_configured_desktop_backends(self):
        config = configparser.ConfigParser()
        config.read(ROOT / "packages/niri/.config/xdg-desktop-portal/niri-portals.conf")
        routes = config["preferred"]
        self.assertEqual(routes["default"], "gnome;gtk;")
        for interface, backend in (("FileChooser", "gtk"), ("ScreenCast", "gnome"),
                                   ("Screenshot", "gnome"), ("Access", "gtk"),
                                   ("Notification", "gtk"), ("Secret", "gnome-keyring")):
            self.assertEqual(routes[f"org.freedesktop.impl.portal.{interface}"], backend + ";")

    def test_kde_polkit_agent_is_started_directly_and_checked_by_doctor(self):
        agent = "/usr/libexec/kf6/polkit-kde-authentication-agent-1"
        startup = (ROOT / "packages/niri/.config/niri/autostart.kdl").read_text()
        self.assertIn(f'spawn-at-startup "{agent}"', startup)
        self.assertIn(agent, (ROOT / "scripts/doctor.sh").read_text())
        self.assertNotIn("polkit-gnome", startup)

    def test_clipboard_watchers_are_supervised_and_session_scoped(self):
        startup = (ROOT / "packages/niri/.config/niri/autostart.kdl").read_text()
        self.assertNotIn('spawn-sh-at-startup "wl-paste', startup)
        for kind in ("text", "image"):
            name = f"dotfiles-clipboard-{kind}.service"
            self.assertIn(name, startup)
            service = (ROOT / "packages/fuzzel/.config/systemd/user" / name).read_text()
            self.assertIn("PartOf=graphical-session.target", service)
            self.assertIn("After=graphical-session.target", service)
            self.assertIn("Restart=on-failure", service)
