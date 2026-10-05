# CachyOS laptop dotfiles (Niri + componentes GNOME)

The Ansible playbook `setup.yml` configures CachyOS, ordered to catch
cheap failures before changing the machine:

1. Validates the repository configuration and tests.
2. Runs a full system upgrade and installs the packages in
   [system-packages/cachyos.txt](system-packages/cachyos.txt) one at a time, with
   numbered progress. Packages are grouped by purpose and alphabetized within
   each group, including `stow`, `podman`, `distrobox` and `epiphany` (GNOME Web).
3. Adds user Flathub and removes the system Flathub remote.
4. Enables the required system and user services.
5. Downloads and installs the configured fonts under the user data directory.
6. Links dotfiles with GNU Stow, backing up conflicts first.

**The full playbook requires sudo access and only installs packages on CachyOS.**
It uses your existing pacman repositories and v4 CPU/repository selection.
For the minimal GNOME scope, x86-64-v4
eligibility and security checklist, read [docs/cachyos.md](docs/cachyos.md).
This is a Niri
session with selected GNOME components, not a full GNOME Shell session.

## Usage

```sh
make setup
```

Run as your normal user, **not** with `sudo make`. `make setup` verifies CachyOS
and that Python is available, then creates a user-owned Python virtual
environment at `.venv`, activates it for the playbook command, and installs the
complete `ansible` distribution from `requirements-ansible.txt` there with pip.
That distribution supplies the `community.general.pacman` module used for
package management. Ansible asks for the sudo password once at startup and
keeps it only in memory for privileged package, service and remote-removal tasks. Ansible then checks
the user, operating system and package manifest, runs the non-mutating static
checks, and only then asks the Pacman module to perform a full system upgrade.
A second Pacman task loops over the manifest and shows `n/total package` for
each item. The module deliberately separates `upgrade` and `name`; afterward
the workflow configures Flathub and services, installs fonts and links dotfiles.
Python is assumed to be
part of the base installation and is **not** installed by this repository.
On other distributions, `make setup` **stops before making changes**; use
`make local` to install only fonts and dotfiles (requires their tools).

```sh
make packages   # CachyOS upgrade/install, user Flathub and services
make services   # reapply service setup; install packages first
make libvirt    # repair libvirt sockets and verify QEMU/network/storage access
make local      # fonts, links, checks; no system packages
make fonts      # only fonts
make dotfiles   # only Stow links
make flatpak    # user Flathub remote and apps; NEVER part of setup
make check      # static Bash/JSON/residue checks
make doctor     # machine commands, app configs, and every managed symlink
make verify     # static checks plus doctor
```

Every installation target reuses the same virtual environment and creates it
if missing. `setup`, `packages`, `services` and `libvirt` use sudo. Plain `make` only lists targets.
To run the complete playbook directly, run `source .venv/bin/activate` first
and pass `--ask-become-pass` (or `-K`) to `ansible-playbook`.
`--check` validates the preconditions but **skips** pacman, service setup,
Flatpak remote configuration, fonts, Stow and checks: it is not a simulation
of the installation or its backups.

Before invoking GNU Stow, the dotfiles task moves every unmanaged conflicting
file or link to a sibling backup named `.bak` (or `.bak.N` when that name is
already occupied). It never deletes existing data and reports every backup it
creates. Files already linked to this repository are left untouched.
When migrating, only old Rofi symlinks pointing to this repository are removed;
unrelated Rofi files and settings are not touched.

## Prerequisites

On CachyOS, an existing clone needs `make`, `bash`, `python3`, `pacman` and `sudo` to run
`make setup`. For a fresh clone, install `git` and `make` first:
`sudo pacman -Syu --needed git make`. Ansible is written in Python, but
Python alone does not include `ansible-playbook`; `make setup` installs it
into the virtual environment, never as a system package.
The playbook installs `stow`, `curl`, `fontconfig`, desktop applications and
the other declared dependencies before using them. Bootstrap also needs `git`.
`make doctor` checks commands, enabled/active service units, Flatpak remote
scopes and Bluetooth adapter/radio state, as well as audio, networking,
clipboard, brightness, locking, and D-Bus helpers.

Select **Niri** at GDM (not a plain `niri` TTY invocation) after running
the playbook, then run `make doctor`.

Static checks cannot prove hardware or graphical integration. After applying
the dotfiles, log into Niri on the laptop and run:

```sh
make doctor
```

## Services

`make setup` and `make packages` enable and start `NetworkManager.service`,
`bluetooth.service` and `tailscaled.service`. They enable `gdm.service` for the
next boot and stop with an explanation if another display manager is enabled.
User units `pipewire.socket`, `pipewire-pulse.socket`, `wireplumber.service`
and `podman.socket` are enabled and started as your normal user.
The [Podman API uses socket activation](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html).
Distrobox and Epiphany need no dedicated service. Portals and keyring use
D-Bus/session activation; Niri starts polkit and the idle daemon.

Run `make services` to reapply these units after packages are installed.
Libvirt uses the [modular daemons](https://libvirt.org/daemons.html#switching-to-modular-daemons):
QEMU, network, storage, host devices, filters, secrets, interfaces and the local
compatibility proxy. The workflow disables the conflicting legacy
`libvirtd.service` and sockets, then starts the driver sockets (including their
read-only/admin variants) and the logging/locking sockets. It verifies
`qemu:///system` access to VM, network and storage lists as the normal user.
`make libvirt` repeats only this repair and verification. `make doctor` also
checks the connections. No VM NAT network is started automatically.

## Tailscale

`make setup`/`make packages` install `tailscale` through the numbered Pacman
loop and enable/start `tailscaled.service`. This is the same installation
method that the [official installer](https://tailscale.com/install.sh) selects
for CachyOS. `make services` reapplies the service configuration, and
`make doctor` checks the commands and enabled/running daemon.

After installation, [sign in to your tailnet](https://tailscale.com/docs/install/linux):

```sh
sudo tailscale up
```

Follow the authentication URL displayed in your terminal. Setup does not
store credentials or perform account authentication.

## Desktop controls

The desktop follows vanilla **Adwaita Dark**, with the requested `#ff7800`
active window border, tab indicator, workspace selection and launcher selection.
Niri uses quiet gray inactive borders, 12-pixel corners and soft shadows.
Fuzzel and Mako use Adwaita's raised `#36363a` surface; Waybar uses solid
`#222226` chrome at 36 pixels high. Normal status indicators are neutral;
amber, red and green communicate warnings, urgency and charging.
`Super+Return`, Fuzzel and Waybar actions open Kitty. Mako notifications use a
raised Adwaita surface. Kitty uses Adwaita Mono, a `#1d1d20` text surface,
orange selections and tabs, and the GNOME terminal palette. Bash keeps a
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

See the [research and palette](docs/adwaita-theme.md),
[desktop](docs/screenshots/desktop-adwaita-orange.png),
[launcher](docs/screenshots/launcher-adwaita-orange.png) and
[notifications](docs/screenshots/notifications-adwaita-orange.png).

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
locks before sleep. Swaylock shows the Adwaita wallpaper and a visible orange
unlock indicator; type your password and press Enter. Caps Lock and the keyboard
layout are shown while typing. The display wakes on activity and after suspend.
Missing wallpaper or appearance settings fall back to a solid dark lock screen.
Install both `swaylock` and `swayidle`, run the dotfiles task,
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
with `Super+Shift+D`). It reports an inactive Bluetooth service with the repair
command `make services`, detects hardware blocks and can power on a soft-blocked
adapter, search for nearby devices, pair/connect, disconnect, and forget them.
It uses `bluetoothctl` (BlueZ) and `rfkill`; no additional Bluetooth
interface is needed. Pairing that requires a PIN may need an interactive
Bluetooth agent. This menu is part of the `fuzzel` Stow package and is linked
automatically by the dotfiles task.

## Fonts

The fonts task installs IBM Plex Mono Nerd Font, JetBrains Mono Nerd Font, and
Inter into `${XDG_DATA_HOME:-$HOME/.local/share}/fonts`. Archives are cached in
`${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/fonts` and `fc-cache` is refreshed.
The system manifest installs `adwaita-fonts` and `adwaita-icon-theme` for the
desktop's native typography and icons. Nerd Fonts remain available for symbols.

## Shell

`make setup` installs `zsh`, `zsh-completions`, and `starship`. Stow links
`~/.zshrc`, `~/.bashrc`, `~/.profile`,
`~/.config/starship.toml` and the optional `~/.local/bin/fedora-terminal`.
Zsh loads Starship and standard completions; Oh My Zsh, its plugins, fnm,
uv, pnpm, and zoxide are only used if already installed. The Fedora Distrobox
aliases and tmux hook activate only in that container. No login shell is
changed automatically; start `zsh` manually if you want to use it.

## Flatpak apps (separate opt-in)

Run `make flatpak` **only when you want the applications**. It does not run in
`make setup`. The apps and extensions are listed in
[flatpak-apps/flathub.txt](flatpak-apps/flathub.txt). It adds Flathub to the
**user** Flatpak installation (`flatpak remote-add --user --if-not-exists`)
and installs each ID with `flatpak install --user`; it does not use sudo or
add a system remote. `make setup`/`make packages` install the `flatpak` command
and configure user Flathub using
`flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`,
then remove the system Flathub remote with sudo. The user remote is created
first so a download failure leaves the system remote available. Removal uses
no `--force`: if installed system apps/runtimes still depend on Flathub,
Flatpak refuses removal; migrate those installations before rerunning.
The `flatpak run com.valvesoftware.Steam` entry in the
original list is treated as an **installation** of Steam; nothing is launched.
If any app/extension is unavailable, the command reports the failing ID;
rerun after resolving it. Existing user installations are skipped.

## Bootstrap

The bootstrap script invokes `make setup`, including Ansible bootstrapping and
system package installation. On CachyOS with `git` and `make` already installed:

```sh
DOTFILES_REPO_URL="https://github.com/USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
bash bootstrap-dotfiles.sh
```
