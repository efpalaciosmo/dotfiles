# Dotfiles — Tumbleweed Distrobox & Arch Linux

Reproducible, profile-driven automation for two environments:

- **Arch Linux host** (`arch`) — full desktop install: pacman package set
  (incl. niri, waybar, mako, rofi, foot), shell, prompt, and a 100%
  plugin-free Neovim config.
- **openSUSE Tumbleweed Distrobox** (`tw-vm`) — manually entered container
  used for development tooling (zypper, VS Code Insiders, full Neovim with
  plugins, language stacks).

The Tumbleweed profile is container local. The Arch profile is the only one
that touches the host system package manager (`sudo pacman -S --needed`).

## Layout

```text
.
├── packages/
│   ├── git/              # Git config (arch)
│   ├── shell-arch/       # Arch host shell config (zsh + bash + profile)
│   ├── shell-container/  # Tumbleweed shell config (zsh + bash + profile)
│   ├── nvim-arch/        # Arch Neovim config (PLUGIN-FREE, built-ins only)
│   ├── nvim-vm/          # Tumbleweed Neovim config (plugin-based)
│   ├── starship/         # Prompt (both profiles)
│   ├── niri/             # Niri Wayland compositor (arch)
│   ├── waybar/           # Status bar (arch)
│   ├── mako/             # Notifications (arch)
│   ├── rofi/             # Launcher / scripts (arch)
│   └── foot/             # Terminal (arch)
├── roles/                # Ansible roles
├── tasks/                # profile-tw-vm.yml, profile-arch.yml
├── group_vars/all.yml    # Fonts, package lists, stown lists
├── playbook.yml          # -e dotfiles_profile=tw-vm|arch
├── playbook-doctor.yml
├── bootstrap-dotfiles.sh
├── Makefile
└── README.md
```

`stown` links each package subtree under `packages/` into `$HOME`. The
active package lists are `stown_packages_tw_vm` and `stown_packages_arch`
in `group_vars/all.yml`.

## Targets

```bash
make setup          # .venv + ansible-core + collections + inventory.ini
make check          # syntax checks for tw-vm, and arch
make verify         # check + partial-tag guard
make doctor         # local command and dotfile diagnostics

make arch           # Arch Linux host profile (sudo pacman + dotfiles)
make tw-vm          # Tumbleweed Distrobox profile

make dry-run-arch
make dry-run-tw-vm

# Arch host partials
make packages-arch        # pacman -S --needed (sudo)
make python-user-tools    # pip --user + stown (PYTHON_USER_TOOLS_PROFILE=arch)
make fonts-arch
make languages-arch
make starship-arch
make shell-plugins-arch
make stown-arch

# Tumbleweed Distrobox partials
make packages-tw-vm
make python-user-tools    # pip --user + stown (default profile is tw-vm)
make fonts-tw-vm
make vscode-insiders
make languages-tw-vm
make starship-tw-vm
make shell-plugins-tw-vm
make stown-tw-vm
make podman-compose
```

Temporary compatibility aliases exist for the main profiles: `make vm` runs `make tw-vm`.

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

`make arch` runs, in order:

1. `sudo pacman -Sy` then `sudo pacman -S --needed --noconfirm <pkgs>` for
   the full Arch package set; enables `NetworkManager.service` and
   `bluetooth.service` and ensures the user is in `wheel`.
2. Bootstraps `pip --user` (with `--break-system-packages` because Arch is
   PEP 668 / externally-managed) and installs `stown`.
3. Installs Nerd Fonts into `~/.local/share/fonts`.
4. Installs language tools (fnm/uv/pnpm) into `~/.local`.
5. Installs Starship and oh-my-zsh plugins into `~/.local`.
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

## Tumbleweed Distrobox

Create and enter the Tumbleweed Distrobox manually, then run:

```bash
make setup
DRY_RUN=1 make tw-vm
make tw-vm
```

`make tw-vm` runs, in order:

1. Installs the Tumbleweed package set with `zypper` (`--non-interactive`,
   `--no-recommends`).
2. Bootstraps `pip --user` and installs `stown`.
3. Installs Nerd Fonts into `~/.local/share/fonts`.
4. Installs VS Code Insiders from the Microsoft RPM repo.
5. Installs the development language stack (Go via gvm, fnm, Julia, JDK
   via SDKMAN, uv, Gradle, pnpm) into `~/.local`.
6. Installs Starship and oh-my-zsh plugins into `~/.local`.
7. Links the `tw-vm` stown packages: `nvim-vm`, `shell-container`,
   `starship`.
8. Installs `podman-compose` via `pip --user`.

## Bootstrap

```bash
DOTFILES_REPO_URL="https://github.com/YOUR_USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
PROFILE="arch" \
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USER/dotfiles/main/bootstrap-dotfiles.sh)
```

Defaults:

- `DOTFILES_DIR` → `$HOME/Projects/dotfiles`
- `PROFILE` → `tw-vm` (also accepts `arch`).

## Checks

```bash
make check
DRY_RUN=1 make arch
DRY_RUN=1 make tw-vm
nvim --headless -c 'checkhealth' -c qa   # arch / tw-vm
```

Expected behavior:

- `make arch` calls `sudo pacman -S --needed` (no other system package
  manager).
- `make tw-vm` uses `zypper`, not `dnf`.
- The Arch Neovim config (`packages/nvim-arch`) loads without requiring
  any plugins on disk; missing LSP servers are silently skipped.
- The full plugin-based Neovim config is VM-only.

## Notes

- Wrong-target execution is intentionally not guarded; profiles are
  selected by the command you run.
- The project-local `.venv/` (built by `make setup`) is bound to the
  Python interpreter that created it. If you bind-mount this repo into
  a different environment (a Distrobox container, another machine,
  after a Python upgrade), `make setup` detects the broken venv via
  `ansible-playbook --version` and rebuilds it automatically. You can
  also force a rebuild with `rm -rf .venv && make setup`.
