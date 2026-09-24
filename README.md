# Fedora Silverblue laptop dotfiles

This repository does exactly three things:

1. Downloads and installs the configured fonts under the user data directory.
2. Uses the GNU Stow already installed by Fedora.
3. Links and validates the dotfiles for Niri, Waybar, Rofi, Ghostty, Mako,
   Neovim, Git, Starship, and the shell.

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
Ghostty, Mako, Neovim, Starship and every graphical-session helper beforehand
from Fedora; this repository only configures and validates them. `make doctor`
checks the complete runtime, including audio, networking, clipboard,
brightness, locking, and D-Bus helpers.

Static checks cannot prove hardware or graphical integration. After applying
the dotfiles, log into Niri on the laptop and run:

```sh
make doctor
```

## Desktop controls

The night-sky wallpaper drives the violet/blue palette across Niri, Waybar,
Rofi, Mako and Ghostty. Niri opens windows at half width so two fit on the
1920×1200 laptop screen; `Super+F` maximizes a column. The slim bar sits at the
bottom and keeps playback, connection, audio, load, battery and clock visible. Hover
for details; click the network indicator for connection settings, the clock for
a calendar, and CPU or memory for a system monitor (`btop` if installed, `top`
otherwise).

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
