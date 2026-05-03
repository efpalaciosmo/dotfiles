# Dotfiles — Arch Linux (Niri) + Distrobox Fedora 44

Reproducible, idempotent automation for an **Arch Linux** host with **Niri**, Wayland, and related configs under `packages/`, plus a **Fedora 44** development container in **Distrobox**.

> The host package baseline is managed with `pacman` first; heavier development tooling still lives in the Fedora Distrobox container.

## Layout

```text
.
├── packages/             # stow/stown trees (paths mirror $HOME)
│   ├── mako/             # .config/mako/…
│   ├── foot/             # .config/foot/…
│   ├── niri/             # .config/niri/… + .config/xdg-desktop-portal/…
│   ├── rofi/
│   ├── waybar/
│   ├── shell/            # host shell dotfiles
│   ├── git/
│   ├── nvim/
│   ├── shell-container/  # container shell (Zsh, GOPATH, …) — stown on vm profile
│   ├── git-container/    # optional Git config for the container (not in default stown list)
│   └── starship/
├── roles/                # Ansible roles (common, home, vm_*, dotfiles, …)
├── tasks/                # profile-home.yml, profile-vm.yml
├── group_vars/all.yml    # pacman packages, Flatpaks, Fedora packages, fonts, stown lists, …
├── playbook.yml          # -e dotfiles_profile=home|vm
├── playbook-doctor.yml
├── ansible.cfg
├── inventory.ini.example # make setup → inventory.ini
├── requirements.yml      # community.general (Flatpak, …)
├── requirements-ansible.txt
├── bootstrap-dotfiles.sh # clone/update then make setup && make <profile>
├── Makefile              # ansible-playbook + tags (CLI entry points)
├── architecture.md       # deeper design notes
├── README.md
└── .gitignore
```

Single repo; separation is by **profile** (`home` vs `vm`), not by branches. **stown** links each subtree under **`packages/`** into `$HOME` (same idea as **GNU Stow**). Which packages apply on the host vs in the container is defined in **`group_vars/all.yml`** (`stown_packages_host` / `stown_packages_vm`). Ansible drives the system; **`make home`** and **`make vm`** are Ansible profiles, not folder names.

## Principles

- **Idempotent**: `make home` and `make vm` are safe to run repeatedly.
- **Reversible**: conflicts are moved to `~/.dotfiles-backup/YYYYmmdd-HHMMSS/` before applying **stown**.
- **Non-destructive**: existing real files are not overwritten without a backup.
- **Dry-run**: `DRY_RUN=1 make home|vm` runs `ansible-playbook --check` (best effort; external installers may not fully simulate).
- **Ansible venv**: `make setup` creates `.venv/`, installs `ansible-core`, and pulls collections without a system-wide Ansible.

## Makefile targets

```bash
make setup        # .venv + ansible-core + community.general in .ansible/collections + inventory.ini
make help         # list all targets
make doctor       # validation role / playbook-doctor
make check        # ansible-playbook --syntax-check (+ ansible-lint if installed)
make verify       # check + guard: partial targets must not use `,home` / `,vm` in --tags

make home         # HOST profile  (Arch Linux host)
make vm           # VM profile    (inside: distrobox enter fedora)

make dry-run-home # same as DRY_RUN=1 make home
make dry-run-vm

# Host helpers
make packages-home
make fonts-home
make flatpaks
make distrobox
make language-home
make languages-home
make starship-home
make shell-plugins-home
make stown-home

# pip + stown: same target on host (home) or in Distrobox (vm); profile auto-detected unless overridden
make python-user-tools

# Container helpers
make fonts-vm
make packages-vm
make vscode-insiders
make podman-compose
make starship-vm
make languages-vm
make shell-plugins-vm
make stown-vm
```

## Quickstart

### On the host (Arch Linux)

```bash
git clone https://github.com/YOUR_USER/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
make setup           # first run: venv, collections, inventory.ini
make doctor          # optional: inspect environment
make dry-run-home    # optional: Ansible check mode
make home
```

`make home` (full profile) roughly:

1. Runs **common**: ensures you are not inside Distrobox and prepares the user-local layout.
2. Ensures `~/.local/bin` and related dirs exist; ensures `~/.profile` references `.local/bin` without rewriting stown-managed shell rc files.
3. Upgrades the Arch system and installs `home_pacman_packages` with **pacman**.
4. Installs fonts (IBMPlexMono and JetBrainsMono Nerd Fonts **v3.4.0**, plus Inter **v4.1**) under `~/.local/share/fonts/nerd-fonts/`.
5. Installs **Distrobox** under `~/.local` (user prefix).
6. Creates the **`fedora`** container from `quay.io/fedora/fedora:44-x86_64` with `--home` set to `$HOME/Projects/fedora` (see `group_vars/all.yml` for overrides).
7. Inside the container, symlinks **`/usr/local/bin/podman`** -> **`/usr/bin/distrobox-host-exec`** so container `podman` uses the host.
8. Configures **Flathub** as a **user** remote. If a **system** remote named `flathub` exists, `make flatpaks` adds `--ask-become-pass` so Ansible can remove it with sudo. Installs apps from `flatpak_apps` with **`--user`**.
9. Bootstraps **pip** for `--user` and installs **stown**.
10. Installs host language tools: **fnm**, **uv**, and **pnpm**.
11. Installs **Starship**, **oh-my-zsh**, and zsh plugins.
12. Applies host dotfiles: packages listed in **`stown_packages_host`** (`foot`, `git`, `mako`, `niri`, `nvim`, `rofi`, `shell`, `starship`, `waybar`).

### In the container (Distrobox Fedora)

```bash
distrobox enter fedora
cd ~/Projects/dotfiles    # repo on the shared home / bind mount
make doctor
make dry-run-vm
make vm
```

`make vm` (full profile) order matches `tasks/profile-vm.yml`:

1. Ensures you are **inside** Distrobox and **Fedora** is reported as the distribution.
2. **Common**: same `~/.local` layout; on vm, `~/.profile` gets the PATH line only if `.local/bin` is not already referenced (leaves room for SDKMAN and similar).
3. **`dnf`**: installs the Fedora package sets in `group_vars/all.yml` (`vm_pkg_*`).
4. **Starship** → `~/.local/bin` (upstream install script).
5. **Python user tools**: `get-pip` + **stown** (`pip --user`), with PEP 668 handling as configured.
6. **Nerd Fonts** (same version/layout as the host).
7. **VS Code Insiders** from Microsoft’s repo; default app for `text/plain` via `xdg-mime` where applicable.
8. **Languages / runtimes**: **Go** via **gvm**, **fnm**, **Julia** via **juliaup**, **Java** via **SDKMAN!**, **uv**, **Gradle**, **pnpm** (each can be skipped with `SKIP_*=1` env vars — see `group_vars/all.yml`).
9. **oh-my-zsh** and plugins.
10. **stown** applies vm packages: **`stown_packages_vm`** — **`nvim`**, **`shell-container`**, **`starship`** (keeps Zsh/rc files managed after SDKMAN and friends).
11. **podman-compose** via `pip --user`.

## Remote bootstrap

On a new machine before the repo exists:

```bash
DOTFILES_REPO_URL="https://github.com/YOUR_USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
PROFILE="home" \
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USER/dotfiles/main/bootstrap-dotfiles.sh)
```

Defaults:

- `DOTFILES_DIR` → `$HOME/Projects/dotfiles`
- `PROFILE` → `home` (use `vm` when already inside the container)
- `DOTFILES_REPO_URL` is required if the directory does not exist yet.

## Dry-run mode

With `DRY_RUN=1`, `make home` and `make vm` pass `--check` to Ansible. External installers may not fully respect check mode; treat it as a preview.

```bash
DRY_RUN=1 make home
DRY_RUN=1 make vm
make dry-run-home
make dry-run-vm
```

## Backups

When a target already exists (real file or wrong symlink), the **dotfiles** role moves it to:

```text
$HOME/.dotfiles-backup/YYYYmmdd-HHMMSS/<path-relative-to-$HOME>
```

Inspect or restore:

```bash
ls -la ~/.dotfiles-backup/
ls ~/.dotfiles-backup/$(ls -1tr ~/.dotfiles-backup | tail -n1)
mv ~/.dotfiles-backup/<stamp>/.zshrc ~/.zshrc   # example restore
```

## Revert / cleanup

### Remove a Flatpak installed by this repo

```bash
flatpak --user uninstall com.valvesoftware.Steam
flatpak --user uninstall --all          # removes all user Flatpaks — be careful
```

### Remove / recreate the `fedora` container

```bash
distrobox stop fedora
distrobox rm fedora
make distrobox       # recreates it (idempotent)
```

> If you change `distrobox_image` or `distrobox_container_home` in `group_vars/all.yml` (or via extra vars) before `make distrobox`, that configuration is what gets used.

### Remove VS Code Insiders from the container

```bash
distrobox enter fedora -- sudo dnf remove -y code-insiders
distrobox enter fedora -- sudo rm -f /etc/yum.repos.d/vscode.repo
```

### Remove Nerd Fonts installed by the fonts role

```bash
rm -rf ~/.local/share/fonts/nerd-fonts
fc-cache -f ~/.local/share/fonts
```

## Debugging PATH

```bash
make doctor            # prints PATH and checks ~/.local/bin
echo "$PATH" | tr ':' '\n'
ls -la ~/.local/bin
grep -n 'PATH' ~/.profile ~/.bashrc ~/.zshrc 2>/dev/null
```

If `~/.local/bin` is missing from `PATH`, open a new login session or `source ~/.profile`. Local tools (Distrobox, **stown**, **podman-compose**) are expected there.

## Arch host rules

- Host packages are installed with `pacman` through `home_pacman_packages`.
- `niri`, `waybar`, and the helper CLIs used by Waybar/Niri/rofi are part of `home_pacman_packages`.
- Do not install VS Code Insiders or dev toolchains on the host profile.
- `sudo` is limited to what the playbooks need: pacman and, when applicable, removing a **system** `flathub` remote.
- Flatpaks are installed **`--user`**.
- User binaries live in `~/.local/bin`.
- Fonts live under `~/.local/share/fonts/`.

## Notes

- **VS Code Insiders desktop file**: often `code-insiders.desktop`. Role `vm_vscode` prefers Insiders, then falls back to `code.desktop`.
- **`podman` in the container**: should resolve to **`/usr/bin/distrobox-host-exec`** via `/usr/local/bin/podman`. Verify with `make doctor` or:
  ```bash
  command -v podman && readlink -f "$(command -v podman)"
  ```
  If you see `host-spawn` errors, exit and re-enter the container (`distrobox stop fedora && distrobox enter fedora`).
- **PEP 668 / externally-managed environments**: if `pip` refuses **stown**, retry with:
  ```bash
  ALLOW_PIP_BREAK_SYSTEM_PACKAGES=1 make python-user-tools
  ```
  On non-ostree **home** profiles, the playbook may allow break-system-packages for user installs automatically — see `pip_break_allowed` in `group_vars/all.yml`.
- **Flatpaks after install**: you may need to log out and back in for **user** Flatpaks to show up in the app menu (`XDG_DATA_DIRS`).
- **Terminal fonts**: the fonts role does not change your terminal emulator. Set the font manually, e.g. **JetBrainsMono Nerd Font**, **IBMPlexMono Nerd Font**, or **Inter**; check with `fc-match 'Inter'`.
- **`GOPATH`**: after the vm profile, `packages/shell-container` sets `GOPATH="$HOME/.go"` in the managed shell startup — open a new shell or `source` the relevant file before expecting `echo "$GOPATH"`.

## Acceptance checks

On the host:

```bash
make check
make doctor
DRY_RUN=1 make home
make home
command -v distrobox
distrobox list
flatpak remotes --user | grep flathub
flatpak list --user
fc-match "JetBrainsMono Nerd Font"
```

Inside the container (`distrobox enter fedora`):

```bash
cd ~/Projects/dotfiles
make check
make doctor
DRY_RUN=1 make vm
make vm
command -v code-insiders
xdg-mime query default text/plain        # often code-insiders.desktop
command -v podman-compose
podman version
podman-compose --help
# After a new login shell:
echo "$GOPATH"                            # expect $HOME/.go per shell-container config
```

## License

Personal configuration. Use at your own discretion.
