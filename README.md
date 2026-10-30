# Niri desktop dotfiles and CachyOS post-install

Install a minimal CachyOS base, then run **`make`** from this clone as your
normal user. It installs the system and synchronizes the dotfiles; you do not need to
run a separate installer command or prepare a JSON configuration file.

## CachyOS: minimal base → `make`

1. Install a supported **minimal CachyOS x86_64** system with working networking,
   Git, Make and a regular account authorized to use sudo. Have this repository
   available on that system. No GNOME/Niri desktop preset is needed.
2. Run:

```sh
make
```

The full workflow runs `make setup` and then `make dotfiles`, sequentially even
with `make -j`. A failed setup prevents linking. Setup bootstraps Python if missing, runs repository checks, detects hardware,
preserves an existing firewall/power stack where possible, shows the signed
repository installation plan, asks for sudo and installs the fixed **workstation**
defaults: GNOME + Niri in GDM, Ghostty, desktop/hardware/network/audio/power tools,
per-user Flathub, Podman/Distrobox, x86 virtualization with 3D/SPICE/PipeWire/USB
backends, ARM guests and ARM container emulation, Tailscale and security-key
tools. These are included by default, not a feature menu. It enables the required
services for the next boot, generates `en_US.UTF-8` without changing the global
language, and fills missing rootless Podman subordinate-ID mappings using a
reviewed free range. No browser, extensions, Flatpak apps, guest images or containers are
preinstalled.

There are interactive review/safety questions, including recording actual tested
backup/recovery evidence in the command itself. Setup does not invent passing
tests, overwrite conflicting system configuration, authenticate Tailscale, change PAM
or reboot. After setup, `make` links personal configurations and the Adwaita dark/orange
theme with GNU Stow, backing up user-file conflicts. Reboot deliberately when ready, then select
Niri or GNOME in GDM. Intel VA-API generation and unsupported/ambiguous hardware
may require an explicit choice; hardware and recovery still need real testing.

No profile, module-selection flags or Make parameters are required or accepted
by the setup entry point. `make cachyos-plan` previews the same fixed package
selection without installing anything. Modules are internal organization for
review/testing, not things you need to choose. Hardware-specific drivers and
existing firewall/power integration are still detected rather than blindly
installing competing implementations.

See [CachyOS installation and acceptance](docs/cachyos-install.md) for the exact
defaults, safeguards, limitations and acceptance checks.

## Commands and configuration-only use

Run from your clone as your normal user. System installation is CachyOS-only;
other distributions can use `make dotfiles` with their own prerequisites:

```sh
make dotfiles
```

This user-only workflow validates Niri, Fuzzel and Ghostty, backs up conflicting
user files and links the configuration with GNU Stow. It requires no sudo,
Ansible, virtual environment or package manager.

```sh
make            # setup, then dotfiles: complete installation/configuration
make setup      # CachyOS packages, system configuration and next-boot services only
make local      # full static checks, then dotfiles; no software installation
make dotfiles   # validate and link configuration without the full test suite
make stow       # alias for dotfiles
make check      # static checks and tests; no configuration changes
make doctor     # desktop commands, runtime integration and managed symlinks
make verify     # static checks plus doctor
make help       # list available targets
```

To apply only selected configurations:

```sh
make dotfiles PACKAGES="niri fuzzel waybar mako ghostty desktop"
```

The default Stow packages are `git shell-container starship vi ghostty niri waybar
mako fuzzel desktop`. These are configuration directories under `packages/`,
not software packages to install. They include Ghostty, its bundled Adwaita theme,
desktop appearance, shell and Starship preferences. `make setup` alone never
links these preferences; plain `make` does. Outside CachyOS, setup stops without
installing or linking anything; use `make dotfiles` explicitly.

Before invoking Stow, the helper moves unmanaged conflicting files or links to
sibling backups named `.bak` or `.bak.N`. Existing links into this repository
are preserved or unfolded into individual links. Only legacy Rofi, Vim and Kitty
links owned by this clone are removed during migration. Independent Kitty
configuration and installed software are not deleted. Unmanaged directory
symlinks are backed up themselves, never followed to move external files.

## Personal dotfile prerequisites and sessions

For the configuration-only workflow, provide Bash, Make, Python 3.11 or newer,
GNU Stow and the configured desktop tools through your distribution.
Cloning/updating also requires Git. `make check` uses
only Python's standard library; optional validators run when available.
Applying the `niri`, `fuzzel` or `ghostty` configuration requires the corresponding binary
so its configuration can be validated before files are changed.

The desktop uses Niri, Waybar, Fuzzel, Mako, Ghostty, Swaybg, Swaylock, Swayidle,
wl-clipboard, Playerctl, PipeWire/WirePlumber, NetworkManager, BlueZ, a polkit
agent and the GNOME/GTK portals. GNOME Settings and Nautilus provide desktop
integration. `make setup` supplies these tools, fonts and service enablement on
CachyOS; other distributions must provide them. The desktop uses Adwaita Sans,
Adwaita Mono and a Nerd Font for symbols.

Select **Niri** at the login screen after applying the configuration, then run
`make doctor`. The diagnostic checks desktop runtime availability without
requiring services to be explicitly enabled. Missing requirements exit with
status 1; session checks pending a Niri login exit with status 2.

Menus, shortcut descriptions, Waybar tooltips and notifications generated by
these scripts use English. Niri sets English message and time locales for the
applications it launches, and Waybar's calendar uses `en_US.UTF-8`. Provide that
locale (`make setup` generates it on CachyOS). Log out and back into Niri after changing the language
environment. Notifications from other applications use those applications'
language settings; Mako displays the text it receives.

The `desktop` configuration applies user appearance preferences through
GSettings, including dark mode, orange accent and font names. These preferences
also affect GNOME when using the same account. GNOME display, keyboard and
workspace panels do not configure Niri; use Niri's configuration for them.

Follow [desktop acceptance and recovery](docs/desktop-recovery.md) for manual
session checks and restoring configuration backups.

## Desktop controls

The desktop follows vanilla **Adwaita Dark**, with the requested `#ff7800`
active window border, tab indicator, workspace selection and launcher selection.
Niri uses quiet gray inactive borders, 12-pixel corners and soft shadows.
Fuzzel and Mako use Adwaita's raised `#36363a` surface; Waybar uses solid
`#222226` chrome at 36 pixels high. Normal status indicators are neutral;
amber, red and green communicate warnings, urgency and charging.
`Super+Return`, Fuzzel, XDG terminal launchers and Waybar actions open Ghostty.
Its configuration and `Adwaita Dark Orange` theme are both in the `ghostty`
Stow package. Ghostty uses Adwaita Mono, a `#1d1d20` text surface, orange cursor
and selections, and the GNOME terminal palette; its GTK chrome follows dark Adwaita.
Mako notifications use a raised Adwaita surface. Bash keeps a
compact, colored prompt; Zsh uses the linked Starship Adwaita prompt with
orange directory accents. Vim inherits the editing
essentials (relative numbers, four-space indentation, search and a matching
bracket indicator) in `packages/vi/.vimrc`.

The `desktop` Stow package adds GTK settings, Swaylock colors and Zathura
chrome. Linking it runs `dotfiles-appearance`, which sets GNOME's supported
dark preference, native orange accent, Adwaita icons/cursor and Adwaita fonts.
GTK/libadwaita retain their native styling; GNOME's native orange is `#ed5b00`,
while compositor focus and shell selections use exactly `#ff7800`.
To reapply preferences, run `~/.local/bin/dotfiles-appearance`.

See the [research and palette](docs/adwaita-theme.md). Appearance and hardware
acceptance must be checked in the actual CachyOS desktop; static tests are not
visual certification.

Niri detects desktop monitors automatically and opens windows at half width so two
fit side by side; `Super+F` maximizes a column. The slim bar sits at the
bottom and keeps playback, download/upload speed in Mb/s, audio,
load and clock visible. Hover for details; click the network indicator
for the Wi-Fi menu (right click for connection settings), the clock for
a calendar, and CPU or memory for a system monitor (`btop` if installed, `top`
otherwise).

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
locks before sleep. Swaylock shows the Adwaita wallpaper and a visible orange
unlock indicator; type your password and press Enter. Caps Lock and the keyboard
layout are shown while typing. The display wakes on activity and after suspend.
Missing wallpaper or appearance settings fall back to a solid dark lock screen.
With `swaylock` and `swayidle` installed by setup, apply the dotfiles,
then **log out and back in** to start the idle daemon. `make doctor` checks the
script links, wallpaper and running idle daemon. The wallpaper is the
official GNOME Adwaita Dark wallpaper at
`packages/niri/.config/niri/backgrounds/adwaita-dark.png`, linked at
`~/.config/niri/backgrounds/adwaita-dark.png`; no absolute repository path is used.
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
with `Super+Shift+D`). It reports an inactive Bluetooth service and points to
`systemctl status bluetooth.service` for diagnosis, detects hardware blocks and can power on a soft-blocked
adapter, search for nearby devices, pair/connect, disconnect, and forget them.
It uses `bluetoothctl` (BlueZ) and `rfkill`; no additional Bluetooth
interface is needed. Pairing that requires a PIN may need an interactive
Bluetooth agent. This menu is part of the `fuzzel` Stow package and is linked
automatically by the dotfiles task.

## Shell

With Zsh and Starship installed by setup, Stow links
`~/.zshrc`, `~/.bashrc`, `~/.profile`,
`~/.config/starship.toml` and the optional `~/.local/bin/fedora-terminal`.
Zsh loads Starship and standard completions; Oh My Zsh, its plugins, fnm,
uv, pnpm, and zoxide are only used if already installed. The Fedora Distrobox
aliases and tmux hook activate only in that container. No login shell is
changed automatically; start `zsh` manually if you want to use it.

## Bootstrap

With the prerequisites already present, the bootstrap script clones or updates
the repository and runs `make` (system setup followed by Stow synchronization):

```sh
DOTFILES_REPO_URL="https://github.com/USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
bash bootstrap-dotfiles.sh
```
