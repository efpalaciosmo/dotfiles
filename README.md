# Fedora 44 Dotfiles

Ansible installs packages from the official Fedora repositories, configures
user-local tools, and links configuration files with GNU Stow.

## Prerequisite

GNU Stow is intentionally not installed by this repository. Install it before
running the setup:

```sh
sudo dnf5 install stow
```

## Setup

```sh
make
```

The default setup performs one DNF5 package transaction, installs fonts, `fnm`
and the stable Rust toolchain, applies all Stow packages, runs syntax checks,
and validates required commands and symbolic links. Only the DNF task uses
privilege escalation when the current user is not root; containers must provide
passwordless `sudo`.

For a non-mutating preview:

```sh
DRY_RUN=1 make
```

## Commands

```sh
make setup       # full Fedora setup and validation
make packages    # install packages from Fedora repositories
make fonts       # install pinned user-local fonts
make fnm         # install fnm and the configured Node.js LTS release
make rustup      # install stable Rust, rustfmt, Clippy and rust-analyzer
make dotfiles    # apply packages with GNU Stow
make stow        # alias for make dotfiles
make check       # Ansible syntax checks and ansible-lint when available
make doctor      # validate required commands and managed links
make verify      # checks plus obsolete-tooling guard
```

## Package Policy

System packages come only from Fedora repositories. The main groups are:

- GCC, Clang, CMake, Ninja, GDB, LLDB and Valgrind for C and C++.
- Tree-sitter grammars, Lua, ShellCheck and shfmt.
- Rust is managed with rustup; Fedora provides its Tree-sitter grammar.
- TeX Live, Poppler, ImageMagick and Fedora's free FFmpeg build.
- Common shell, archive, Git and terminal utilities.

Desktop, Wayland, audio, Bluetooth and network-management packages are left to
the host and are not installed inside the container. User fonts, MIME
associations and VS Code settings remain managed for applications installed
from the container.

The repository does not install a container engine or container tooling. It
only manages `~/.config/containers/registries.conf` for installations managed
separately by the user.

Tools without a suitable official Fedora package are reported as optional and
remain manually managed. This includes Neovim 0.12+, Starship, lazygit, yazi,
resvg, StyLua, pnpm, opencode, Juliaup and Harlequin. Fedora
44's Neovim 0.11 package is intentionally not installed because the included
configuration uses Neovim 0.12 APIs.

The only upstream downloads automated by Ansible are:

- IBM Plex Mono Nerd Font, JetBrains Mono Nerd Font and Inter.
- A pinned `fnm` release and the configured Node.js LTS release.
- The pinned official rustup installer and the stable Rust toolchain.

## Rust And Neovim

The Rust setup uses the stable rustup toolchain with `rustfmt`, Clippy and
`rust-analyzer`. Neovim enables completion, diagnostics, code actions, inlay
hints, procedural macros and all Cargo features. Rust files are formatted with
`rustfmt` before saving, and rust-analyzer runs Clippy for project checks.

Rust tooling lives under `~/.cargo` and `~/.rustup`. The shared shell profile
adds `~/.cargo/bin` to `PATH`; Neovim also adds it when launched outside a login
shell. Mason does not install a second copy of rust-analyzer.

The managed MIME associations expect Zen Browser, GNOME Papers and the Claude
URL handler to be installed separately.

## Stow Packages

Configuration is linked from `packages/` with `stow --no-folding`:

- `git`, `shell-container`, `starship`, `nvim-vm`
- `btop`, `containers`, `tmux`, `ghostty`, `opencode`
- `xdg` for `mimeapps.list`
- `vscode` for portable VS Code settings

Existing conflicting files are moved to a timestamped directory under
`~/.dotfiles-backup/` before Stow creates links. Generated application state,
credentials, histories, caches, databases and package locks are not managed.

## Bootstrap

On a fresh Fedora 44 Workstation or Container Image installation:

```sh
DOTFILES_REPO_URL="https://github.com/USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
bash bootstrap-dotfiles.sh
```

The bootstrap installs only Git, Make and Python when missing, verifies that
GNU Stow was installed manually, clones or updates the repository, and runs
`make`.
