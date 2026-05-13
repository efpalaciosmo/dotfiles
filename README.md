# Dotfiles — openSUSE Aeon, Tumbleweed Distrobox & Arch Linux

Reproducible, profile-driven automation for three environments:

- **Arch Linux host** (`arch`) — full desktop install: pacman package set
  (incl. niri, waybar, mako, rofi, foot), shell, prompt, and a 100%
  plugin-free Neovim config.
- **openSUSE Aeon host** (`aeon`) — user-space only: Flatpaks, fonts, local
  user tools, shell/git/starship dotfiles, and a small Vim config.
- **openSUSE Tumbleweed Distrobox** (`tw-vm`) — manually entered container
  used for development tooling (zypper, VS Code Insiders, full Neovim with
  plugins, language stacks).

The Aeon profile stays in user space; the Tumbleweed profile is container
local. The Arch profile is the only one that touches the host system
package manager (`sudo pacman -S --needed`).

## Layout

```text
.
├── packages/
│   ├── git/              # Aeon git config (also linked by arch)
│   ├── shell/            # Aeon shell config
│   ├── shell-arch/       # Arch host shell config
│   ├── shell-container/  # Tumbleweed shell config
│   ├── vim/              # Aeon ~/.vimrc for vim-small
│   ├── nvim-vm/          # Tumbleweed Neovim config (plugin-based)
│   ├── nvim-arch/        # Arch Neovim config (PLUGIN-FREE, built-ins only)
│   ├── starship/         # Prompt (all three profiles)
│   ├── niri/             # Niri Wayland compositor (arch)
│   ├── waybar/           # Status bar (arch)
│   ├── mako/             # Notifications (arch)
│   ├── rofi/             # Launcher / scripts (arch)
│   └── foot/             # Terminal (arch)
├── roles/                # Ansible roles
├── tasks/                # profile-aeon.yml, profile-tw-vm.yml, profile-arch.yml
├── group_vars/all.yml    # Flatpaks, fonts, package lists, stown lists
├── playbook.yml          # -e dotfiles_profile=aeon|tw-vm|arch
├── playbook-doctor.yml
├── bootstrap-dotfiles.sh
├── Makefile
└── README.md
```

`stown` links each package subtree under `packages/` into `$HOME`. The
active package lists are `stown_packages_aeon`, `stown_packages_tw_vm`,
and `stown_packages_arch` in `group_vars/all.yml`.

## Targets

```bash
make setup          # .venv + ansible-core + collections + inventory.ini
make check          # syntax checks for aeon, tw-vm, and arch
make verify         # check + partial-tag guard
make doctor         # local command and dotfile diagnostics

make arch           # Arch Linux host profile (sudo pacman + dotfiles)
make aeon           # Aeon host user-space profile
make tw-vm          # Tumbleweed Distrobox profile

make dry-run-arch
make dry-run-aeon
make dry-run-tw-vm

# Arch host partials
make packages-arch        # pacman -S --needed (sudo)
make fonts-arch
make starship-arch
make languages-arch
make shell-plugins-arch
make stown-arch

# Aeon host partials
make fonts-aeon
make flatpaks
make languages-aeon
make starship-aeon
make shell-plugins-aeon
make stown-aeon

# Tumbleweed partials
make packages-tw-vm
make fonts-tw-vm
make vscode-insiders
make podman-compose
make languages-tw-vm
make starship-tw-vm
make shell-plugins-tw-vm
make stown-tw-vm
```

Temporary compatibility aliases exist for the main profiles: `make home`
runs `make aeon`, and `make vm` runs `make tw-vm`.

## Arch Linux host

Installs the curated pacman package set (niri + Wayland stack, Bluetooth,
NetworkManager, Podman, Python toolchain, fonts, …), bootstraps user-local
tooling, and links the `arch` stown packages.

```bash
git clone https://github.com/YOUR_USER/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
make setup
DRY_RUN=1 make arch                  # check mode (no sudo prompt)
make arch                            # asks for the sudo password
```

`make arch` runs:

1. `sudo pacman -Sy` then `sudo pacman -S --needed --noconfirm <pkgs>` for
   the full Arch package set.
2. Enables `NetworkManager.service` and `bluetooth.service` and ensures the
   user is in `wheel`.
3. Installs Nerd Fonts and language tools (fnm/uv/pnpm) into `~/.local`.
4. Installs Starship and oh-my-zsh plugins into `~/.local`.
5. Bootstraps `pip --user` (with `--break-system-packages` because Arch is
   PEP 668 / externally-managed) and installs `stown`.
6. Links the `arch` stown packages: `git`, `shell-arch`, `starship`,
   `nvim-arch`, `niri`, `waybar`, `mako`, `rofi`, `foot`.

Override `ARCH_BECOME` if you have passwordless sudo for pacman /
systemctl / usermod:

```bash
ARCH_BECOME= make arch
```

### Plugin-free Neovim (`packages/nvim-arch`)

The Arch profile ships a Neovim config that uses **only** built-in
features — there are NO third-party plugins anywhere:

- File explorer: `netrw` (`<leader>e`, `<leader>E`, `-`).
- Fuzzy navigation: `:find` with `path+=**` + `wildoptions=fuzzy,pum,tagfile`,
  plus `:grep` powered by `ripgrep` when available.
- Completion: native `vim.lsp.completion.enable(autotrigger=true)` per
  `LspAttach`, omnifunc fallback, and `<C-x><C-o>` / `<C-n>` for buffer-word
  completion.
- LSP: `vim.lsp.config()` / `vim.lsp.enable()` with full per-server configs
  (lua_ls, pyright, ruff, vtsls, clangd, zls, julials, sqlls, marksman,
  jsonls, yamlls, html, cssls, tailwindcss). Servers are auto-skipped when
  the binary is not on `$PATH`. Run `:LspEnableAll` to re-probe.
- Statusline: hand-rolled in `lua/config/statusline.lua` (mode pill, git
  branch via `.git/HEAD`, file marks, diagnostics, LSP names, position).
- Tree-sitter: built-in `vim.treesitter.start()` driven by `FileType`,
  parsers auto-discovered from system `tree-sitter` install dirs.
- Markdown: built-in syntax + `conceallevel=2` (no rendering plugin).

## openSUSE Aeon host

```bash
git clone https://github.com/YOUR_USER/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
make setup
DRY_RUN=1 make aeon
make aeon
```

`make aeon` runs common user-local setup, installs Nerd Fonts, configures
user Flathub and Flatpaks, installs `stown`, installs small user-local
language helpers, installs Starship and shell plugins, then applies `git`,
`shell`, `starship`, and `vim`.

## Tumbleweed Distrobox

Create and enter the Tumbleweed Distrobox manually, then run:

```bash
cd ~/Projects/dotfiles
make setup
DRY_RUN=1 make tw-vm
make tw-vm
```

`make tw-vm` installs the Tumbleweed package set with `zypper`, installs
VS Code Insiders from the Microsoft RPM repo, installs the development
language stack, then applies `nvim-vm`, `shell-container`, and `starship`.

## Bootstrap

```bash
DOTFILES_REPO_URL="https://github.com/YOUR_USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
PROFILE="arch" \
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USER/dotfiles/main/bootstrap-dotfiles.sh)
```

Defaults:

- `DOTFILES_DIR` → `$HOME/Projects/dotfiles`
- `PROFILE` → `aeon` (also accepts `arch`, `tw-vm`)
- `PROFILE=home` and `PROFILE=vm` are accepted as temporary aliases.

## Checks

```bash
make check
DRY_RUN=1 make arch
DRY_RUN=1 make aeon
DRY_RUN=1 make tw-vm
nvim --headless -c 'checkhealth' -c qa   # arch / tw-vm
vim -Nu ~/.vimrc                          # aeon
```

Expected behavior:

- `make arch` calls `sudo pacman -S --needed`. It does NOT touch flatpaks.
- `make aeon` does not call `pacman`, `dnf`, `zypper`, `transactional-update`,
  or Distrobox creation.
- `make tw-vm` uses `zypper`, not `dnf`.
- The Arch Neovim config (`packages/nvim-arch`) loads without requiring
  any plugins on disk; missing LSP servers are silently skipped.
- The full plugin-based Neovim config is VM-only.

## Notes

- Wrong-target execution is intentionally not guarded; profiles are
  selected by the command you run.
- Flatpaks are installed with `--user`. If a system Flathub remote exists,
  the Aeon Makefile asks for become only for removing that system remote.
- `ALLOW_PIP_BREAK_SYSTEM_PACKAGES=1` enables the PEP 668 retry for `pip
  --user` installs (always on for the `arch` profile).
