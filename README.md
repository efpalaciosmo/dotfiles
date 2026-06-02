# Dotfiles - openSUSE

Reproducible automation for one profile: `suse`.

The profile configures openSUSE with zypper packages, user-local language
tooling, shell plugins, Starship, VS Code Insiders, the plugin-based Neovim
config, and a Niri Wayland desktop stack.

## Layout

```text
.
├── packages/
│   ├── git/              # Git config
│   ├── shell-container/  # Shell config
│   ├── nvim-vm/          # Main Neovim config
│   ├── starship/         # Prompt
│   ├── niri/             # Niri Wayland compositor
│   ├── waybar/           # Status bar
│   ├── mako/             # Notifications
│   ├── rofi/             # Launcher / scripts
│   └── foot/             # Terminal
├── roles/                # Ansible roles
├── tasks/profile-suse.yml
├── group_vars/all.yml    # Package lists, fonts, stown list
├── playbook.yml          # -e dotfiles_profile=suse
├── playbook-doctor.yml
├── bootstrap-dotfiles.sh
└── Makefile
```

`stown` links each package subtree under `packages/` into `$HOME`. The active
package list is `stown_packages_suse` in `group_vars/all.yml`.

## Targets

```bash
make setup          # .venv + ansible-core + collections + inventory.ini
make check          # Ansible syntax checks
make verify         # check + old-profile residue guard
make doctor         # local command and dotfile diagnostics
make audit-suse     # versions/package metadata inside distrobox 'suse'

make suse           # configure openSUSE
make dry-run-suse   # check mode

make packages-suse
make desktop-suse
make python-user-tools
make fonts-suse
make vscode-insiders
make languages-suse
make starship-suse
make shell-plugins-suse
make stown-suse
make podman-compose
```

There are no compatibility aliases. The only accepted profile name is `suse`.

## What `make suse` Does

1. Installs the openSUSE package set with `zypper --non-interactive`.
2. Enables desktop services for NetworkManager, Bluetooth, PipeWire,
   WirePlumber, and PipeWire Pulse when systemd is available.
3. Bootstraps `pip --user` and installs `stown`.
4. Installs Nerd Fonts into `~/.local/share/fonts`.
5. Installs VS Code Insiders from the Microsoft RPM repo.
6. Installs user-local language tooling: Go via gvm, fnm, Julia, JDK via
   SDKMAN, uv, Gradle, and pnpm.
7. Installs Starship and oh-my-zsh plugins.
8. Links the `suse` dotfiles: `git`, `shell-container`, `starship`, `nvim-vm`,
   `niri`, `waybar`, `mako`, `rofi`, and `foot`.
9. Installs `podman-compose` via `pip --user`.

## Niri Desktop

The package list includes Niri and the supporting desktop stack used by the
checked-in configs: Waybar, Mako, rofi-wayland, Foot, swaybg, wl-clipboard,
cliphist, grim, slurp, swappy, PipeWire, WirePlumber, PulseAudio CLI tools,
portals, polkit, NetworkManager tooling, Bluetooth tooling, brightness/audio
and media controls, and notification utilities.

The Niri autostart is written to tolerate optional host-specific tools. For
example, `logid` only runs when installed, and the polkit agent is discovered
from common openSUSE paths.

`xwayland-satellite` is installed for Xwayland support, but Niri starts it
itself on current releases when the binary is available.

## Bootstrap

```bash
DOTFILES_REPO_URL="https://github.com/YOUR_USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
PROFILE="suse" \
bash bootstrap-dotfiles.sh
```

Defaults:

- `DOTFILES_DIR` -> `$HOME/Projects/dotfiles`
- `PROFILE` -> `suse`

## Checks

```bash
make verify
DRY_RUN=1 make suse
make audit-suse
nvim --headless -c 'checkhealth' -c qa
```

Expected behavior:

- `make suse` uses `zypper`.
- No other profile names are accepted.
- Niri, Waybar, Mako, rofi-wayland, Foot, clipboard, screenshot, audio,
  portal, and polkit tooling are installed or reported by `make doctor`.
- `make audit-suse` reports current versions from inside `distrobox enter suse`.
- The main Neovim config is `packages/nvim-vm`.
