# Fedora Silverblue laptop dotfiles

This repository does exactly three things:

1. Downloads and installs the configured fonts under the user data directory.
2. Uses the GNU Stow already installed by Fedora.
3. Links and validates the dotfiles for Niri, Waybar, Rofi, Kitty, Mako,
   vi, Git, and Bash.

It does not install system packages, graphical applications, language runtimes,
shell plugins, or developer tools. Install all required software from Fedora
before running the setup.

## Usage

```sh
make
```

`make` is equivalent to `make setup` and invokes, in order, only `make fonts`,
`make dotfiles`, and `make check`.

```sh
make fonts      # install/update user-local fonts
make dotfiles   # link all packages with the existing stow command
make stow       # alias for make dotfiles
make check      # static Bash/JSON/residue checks
make doctor     # machine commands, app configs, and every managed symlink
make verify     # static checks plus doctor
```

Before invoking GNU Stow, `make dotfiles` moves every unmanaged conflicting
file or link to a sibling backup named `.bak` (or `.bak.N` when that name is
already occupied). It never deletes existing data and reports every backup it
creates. Files already linked to this repository are left untouched.

## Prerequisites

The setup itself needs `git`, `make`, `stow`, `curl`, `tar`, `unzip`, `find`,
`install`, `mktemp`, `python3`, and `fc-cache`. Install Niri, Waybar, Rofi,
Kitty, vi, Mako and every graphical-session helper beforehand
from Fedora; this repository only configures and validates them. `make doctor`
checks the complete runtime, including audio, networking, clipboard,
brightness, locking, and D-Bus helpers.

On Fedora Silverblue, Kitty can be
layered with `sudo rpm-ostree install kitty` followed by a
reboot. Then run `make dotfiles` and `make doctor`.

Static checks cannot prove hardware or graphical integration. After applying
the dotfiles, log into Niri on the laptop and run:

```sh
make doctor
```

## Desktop controls

Niri uses soft lilac (`#d9b8ff`) for focused borders, muted purple for inactive
borders and rose for urgency. Rofi uses the requested plum background (`#241f31`)
with lilac selections. Waybar uses one solid `#241f31` bar with lilac focused
workspaces and restrained status accents. Its 34-pixel height is a little smaller
than the first plum design. Urgent workspaces use rose.
`Super+Return`, Rofi and Waybar actions open Kitty. Mako notifications use a
raised plum surface with lilac, peach and rose accents. Kitty keeps its
existing colors. Bash keeps a compact, colored prompt; vi inherits the editing
essentials (relative numbers, four-space indentation, search and a matching
bracket indicator) in `packages/vi/.virc`.

The [desktop](docs/screenshots/desktop-adwaita-orange.png) and
[launcher](docs/screenshots/launcher-adwaita-orange.png) screenshots show the
previous palette; they have not yet been recaptured in a Niri session.

Niri opens windows at half width so two fit on the
1920×1200 laptop screen; `Super+F` maximizes a column. The slim bar sits at the
bottom and keeps playback, download/upload speed in Mb/s, brightness, audio,
load, battery and clock visible. Hover for details; click the network indicator
for the Wi-Fi menu (right click for connection settings), the clock for
a calendar, and CPU or memory for a system monitor (`btop` if installed, `top`
otherwise). Scroll over the brightness indicator to adjust the screen in 5% steps.

`Super+D` opens applications; `Super+Shift+D` opens quick actions for windows,
clipboard, screenshots, connections, system monitoring, disk usage and power.
`Super+Shift+Y` opens clipboard history, `Super+Shift+S` screenshots,
`Super+Shift+P` power and `Super+Alt+L`
locks the session. In Rofi, `?` switches from applications to recursive file
search under your home directory; `Control+Tab` cycles through the available
modes. Clipboard history uses `wl-paste`, `wl-copy` and the
system Python/SQLite; it keeps at most 60 text or PNG entries (4 MiB each) in
`~/.local/share/dotfiles/clipboard/history.sqlite3`. Clear it in the menu or
with `~/.config/rofi/scripts/clipboard --clear`. Start a new Niri session after
linking the dotfiles to activate its clipboard watchers.

`Super+Shift+N` opens a Wi-Fi menu in Rofi, also available under quick actions.
It lists nearby networks and signal strength, connects with a password prompt
when needed, and can refresh, disconnect, or toggle Wi-Fi. It uses the installed
NetworkManager `nmcli` and Python's standard library.

`Ctrl+B` opens the Bluetooth menu in Rofi (also available under quick actions
with `Super+Shift+D`). It can power on a soft-blocked
adapter, search for nearby devices, pair/connect, disconnect, and forget them.
It uses Fedora's `bluetoothctl` (BlueZ) and `rfkill`; no additional Bluetooth
interface is needed. Pairing that requires a PIN may need an interactive
Bluetooth agent. This menu is part of the `rofi` Stow package and is linked
automatically by `make dotfiles`.

## Fonts

`make fonts` installs IBM Plex Mono Nerd Font, JetBrains Mono Nerd Font, and
Inter into `${XDG_DATA_HOME:-$HOME/.local/share}/fonts`. Archives are cached in
`${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/fonts` and `fc-cache` is refreshed.

## Bootstrap

The bootstrap script installs no dependencies. On a prepared Fedora system:

```sh
DOTFILES_REPO_URL="https://github.com/USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
bash bootstrap-dotfiles.sh
```
