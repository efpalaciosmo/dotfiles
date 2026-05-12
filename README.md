# Dotfiles — openSUSE Aeon + Tumbleweed Distrobox

Reproducible, profile-driven automation for an **openSUSE Aeon** host and a manually entered **openSUSE Tumbleweed Distrobox**.

The Aeon profile stays in user space: Flatpaks, fonts, local user tools, shell/git/starship dotfiles, and a small Vim config. It does not install host RPMs, run `transactional-update`, or create Distrobox containers. The Tumbleweed profile assumes you are already inside the container and uses `zypper` for development packages.

## Layout

```text
.
├── packages/
│   ├── git/              # Aeon git config
│   ├── shell/            # Aeon shell config
│   ├── vim/              # Aeon ~/.vimrc for vim-small
│   ├── nvim-vm/          # Tumbleweed Neovim config
│   ├── shell-container/  # Tumbleweed shell config
│   └── starship/
├── roles/                # Ansible roles
├── tasks/                # profile-aeon.yml, profile-tw-vm.yml
├── group_vars/all.yml    # Flatpaks, fonts, Tumbleweed packages, stown lists
├── playbook.yml          # -e dotfiles_profile=aeon|tw-vm
├── playbook-doctor.yml
├── bootstrap-dotfiles.sh
├── Makefile
└── README.md
```

`stown` links each package subtree under `packages/` into `$HOME`. The active package lists are `stown_packages_aeon` and `stown_packages_tw_vm` in `group_vars/all.yml`. Legacy Niri/Waybar/Mako/Rofi/Foot package directories may still exist in the repo, but they are no longer applied by either profile.

## Targets

```bash
make setup          # .venv + ansible-core + collections + inventory.ini
make check          # syntax checks for aeon and tw-vm
make verify         # check + partial-tag guard
make doctor         # local command and dotfile diagnostics

make aeon           # Aeon host user-space profile
make tw-vm          # Tumbleweed Distrobox profile

make dry-run-aeon
make dry-run-tw-vm

make fonts-aeon
make flatpaks
make languages-aeon
make starship-aeon
make shell-plugins-aeon
make stown-aeon

make packages-tw-vm
make fonts-tw-vm
make vscode-insiders
make podman-compose
make languages-tw-vm
make starship-tw-vm
make shell-plugins-tw-vm
make stown-tw-vm
```

Temporary compatibility aliases exist for the main profiles: `make home` runs `make aeon`, and `make vm` runs `make tw-vm`.

## Aeon Host

```bash
git clone https://github.com/YOUR_USER/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
make setup
DRY_RUN=1 make aeon
make aeon
```

`make aeon` runs common user-local setup, installs Nerd Fonts, configures user Flathub and Flatpaks, installs `stown`, installs small user-local language helpers, installs Starship and shell plugins, then applies `git`, `shell`, `starship`, and `vim`.

## Tumbleweed Distrobox

Create and enter the Tumbleweed Distrobox manually, then run:

```bash
cd ~/Projects/dotfiles
make setup
DRY_RUN=1 make tw-vm
make tw-vm
```

`make tw-vm` installs the Tumbleweed package set with `zypper`, installs VS Code Insiders from the Microsoft RPM repo, installs the development language stack, then applies `nvim-vm`, `shell-container`, and `starship`.

## Bootstrap

```bash
DOTFILES_REPO_URL="https://github.com/YOUR_USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
PROFILE="aeon" \
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USER/dotfiles/main/bootstrap-dotfiles.sh)
```

Defaults:

- `DOTFILES_DIR` -> `$HOME/Projects/dotfiles`
- `PROFILE` -> `aeon`
- `PROFILE=home` and `PROFILE=vm` are accepted as temporary aliases.

## Checks

```bash
make check
DRY_RUN=1 make aeon
DRY_RUN=1 make tw-vm
vim -Nu ~/.vimrc
```

Expected behavior:

- `make aeon` does not call `pacman`, `dnf`, `zypper`, `transactional-update`, or Distrobox creation.
- `make tw-vm` uses `zypper`, not `dnf`.
- Host stown packages are Aeon-safe.
- The full Neovim config is VM-only.

## Notes

- Wrong-target execution is intentionally not guarded; profiles are selected by the command you run.
- Flatpaks are installed with `--user`. If a system Flathub remote exists, the Makefile asks for become only for removing that system remote.
- `ALLOW_PIP_BREAK_SYSTEM_PACKAGES=1` enables the PEP 668 retry for `pip --user` installs.
