# CachyOS laptop dotfiles (Niri + componentes GNOME)

This repository does four things on CachyOS:

1. Runs a full `pacman -Syu --needed` with the packages in
   [system-packages/cachyos.txt](system-packages/cachyos.txt), **including `stow`**.
2. Downloads and installs the configured fonts under the user data directory.
3. Links dotfiles with GNU Stow.
4. Validates the dotfiles for Niri, Waybar, Fuzzel, Kitty, Mako,
   Vim, Git, and Bash.

**`make`/`make setup` requires sudo access and only installs packages on
CachyOS.** It does not enable services, alter pacman repositories, or change
your v4 CPU/repository selection. For the minimal GNOME scope, x86-64-v4
eligibility and security checklist, read [docs/cachyos.md](docs/cachyos.md).
This is a Niri
session with selected GNOME components, not a full GNOME Shell session.

## Usage

```sh
make
```

`make` is equivalent to `make setup`: first `make packages` (one complete
system update and package installation), then fonts, dotfiles and checks.
On other distributions, `make setup` **stops before making changes**;
use `make local` if you only want fonts and dotfiles there.

```sh
make packages   # CachyOS-only: update/install all listed system packages
make local      # fonts + dotfiles + check, without system packages
make fonts      # install/update user-local fonts
make dotfiles   # link all dotfile packages with stow
make stow       # alias for make dotfiles
make check      # static Bash/JSON/residue checks
make doctor     # machine commands, app configs, and every managed symlink
make verify     # static checks plus doctor
```

Before invoking GNU Stow, `make dotfiles` moves every unmanaged conflicting
file or link to a sibling backup named `.bak` (or `.bak.N` when that name is
already occupied). It never deletes existing data and reports every backup it
creates. Files already linked to this repository are left untouched.
When migrating, only old Rofi symlinks pointing to this repository are removed;
unrelated Rofi files and settings are not touched.

## Prerequisites

To run `make setup` in an existing clone you only need `make`, `bash`,
`pacman` and `sudo` initially; it installs `stow`, `curl`, `python3` (package
`python`), `fontconfig`, desktop applications and the other declared
dependencies before using them. Bootstrap also needs `git` to clone the
repository. If missing, first run `sudo pacman -Syu --needed git make`.
`make doctor`
checks the complete runtime, including audio, networking, clipboard,
brightness, locking, and D-Bus helpers.

Select **Niri** at GDM (not a plain `niri` TTY invocation) after running
`make setup`, then run `make doctor`.

Static checks cannot prove hardware or graphical integration. After applying
the dotfiles, log into Niri on the laptop and run:

```sh
make doctor
```

## Desktop controls

Niri uses soft lilac (`#d9b8ff`) for focused borders, muted purple for inactive
borders and rose for urgency. Fuzzel uses a raised plum surface (`#30283f`)
with restrained lilac highlights. Waybar uses one solid `#241f31` bar with lilac focused
workspaces and restrained status accents. Its 34-pixel height is a little smaller
than the first plum design. Urgent workspaces use rose.
`Super+Return`, Fuzzel and Waybar actions open Kitty. Mako notifications use a
raised plum surface with lilac, peach and rose accents. Kitty keeps its
existing colors. Bash keeps a compact, colored prompt; Vim inherits the editing
essentials (relative numbers, four-space indentation, search and a matching
bracket indicator) in `packages/vi/.vimrc`.

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

`Super+V` toggles the focused window between tiled and floating; `Super+Shift+V`
switches focus between those layouts. Niri floats parented dialogs and fixed-size
windows automatically. Zen and Firefox Picture-in-Picture windows open floating
at the bottom right; close and reopen an existing PiP window after changing rules.

`Super+D` opens Fuzzel's native application launcher (desktop icons and launch
history); `Super+Shift+D` opens quick actions for windows, recursive file
search, file browsing, commands, clipboard, screenshots, connections, system
monitoring, disk usage and power.
`Super+Shift+Y` opens clipboard history, `Super+Shift+S` screenshots,
`Super+Shift+P` power and `Super+Alt+L`
locks the session through `~/.config/niri/scripts/lock-screen`. In Niri,
`swayidle` locks after 5 minutes, powers off monitors after 10 minutes and
locks before sleep. Install both `swaylock` and `swayidle`, run `make dotfiles`,
then **log out and back in** to start the idle daemon. `make doctor` checks the
script links, wallpaper and running idle daemon. The wallpaper is the
repository's `packages/niri/.config/niri/backgrounds/bluesky.png`, linked at
`~/.config/niri/backgrounds/bluesky.png`; no absolute repository path is used.
Fuzzel does not support Rofi's in-launcher `?` and
`Control+Tab` mode switching: use `Super+Shift+D` for file search
under home, file browsing, windows and commands instead. Search lists only
files inside home; it skips hidden directory trees (except `~/.config`), caches,
dependencies and generated build files for responsiveness. The file browser
can navigate hidden folders, but cannot leave home. Clipboard history
uses `wl-paste`, `wl-copy` and the
system Python/SQLite; it keeps at most 60 text or PNG entries (4 MiB each) in
`$XDG_RUNTIME_DIR/dotfiles/clipboard/history.sqlite3` (normally discarded
after full logout, unless user lingering is enabled).
Clipboard content can include passwords: clear it in the menu or
with `~/.config/fuzzel/scripts/clipboard --clear`. Start a new Niri session after
linking the dotfiles to activate its clipboard watchers. The former persistent
`~/.local/share/dotfiles/clipboard/` directory is **not deleted automatically**;
remove it yourself after verifying that it contains no data you need.

`Super+Shift+N` opens a Wi-Fi menu in Fuzzel, also available under quick actions.
It lists nearby networks and signal strength, connects with a password prompt
when needed, and can refresh, disconnect, or toggle Wi-Fi. It uses the installed
NetworkManager `nmcli` and Python's standard library.

`Ctrl+B` opens the Bluetooth menu in Fuzzel (also available under quick actions
with `Super+Shift+D`). It can power on a soft-blocked
adapter, search for nearby devices, pair/connect, disconnect, and forget them.
It uses `bluetoothctl` (BlueZ) and `rfkill`; no additional Bluetooth
interface is needed. Pairing that requires a PIN may need an interactive
Bluetooth agent. This menu is part of the `fuzzel` Stow package and is linked
automatically by `make dotfiles`.

## Fonts

`make fonts` installs IBM Plex Mono Nerd Font, JetBrains Mono Nerd Font, and
Inter into `${XDG_DATA_HOME:-$HOME/.local/share}/fonts`. Archives are cached in
`${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/fonts` and `fc-cache` is refreshed.

## Bootstrap

The bootstrap script invokes `make setup`, including system package
installation. On CachyOS with `git` and `make` already installed:

```sh
DOTFILES_REPO_URL="https://github.com/USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
bash bootstrap-dotfiles.sh
```
