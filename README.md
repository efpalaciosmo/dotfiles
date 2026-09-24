# Fedora Distrobox Dotfiles

Ansible installs packages from the official Fedora repositories, configures
user-local tools, and links configuration files with GNU Stow.

## Prerequisite

GNU Stow is intentionally not installed by this repository. Install it before
running the setup:

```sh
sudo dnf5 install stow
```

The local Ansible virtualenv uses Python 3.14. `make` recreates an existing
virtualenv made with another Python version. Run the setup inside the Fedora
Distrobox (`distrobox enter fedora`). Ansible's local modules also use Python
3.14; DNF5 runs through its CLI because Fedora 45's `python3-libdnf5` bindings
are installed for the container's default Python 3.15 instead.

## Setup

```sh
make
```

The default setup installs missing Fedora packages with DNF5 (without weak dependencies),
installs fonts, `fnm`, Node.js and pnpm, applies all Stow packages, runs syntax checks,
and validates required commands and symbolic links. Only the DNF task uses
privilege escalation for package installation and setting the Distrobox user's
login shell to zsh; containers must provide passwordless `sudo`.

Interactive Bash sessions in the Fedora Distrobox switch to zsh, and interactive
zsh sessions attach to the `fedora` tmux session automatically. Detach with
`Ctrl-Space d`; shells inside tmux and non-interactive commands do not attach
again. Neovim, tmux, Starship and btop use the Adwaita Dark palette.

For a non-mutating preview:

```sh
DRY_RUN=1 make
```

## Commands

```sh
make setup       # full Fedora setup and validation
make packages    # install packages from Fedora repositories
make fonts       # install pinned user-local fonts
make fnm         # install fnm, the configured Node.js LTS release and pnpm
make dotfiles    # apply packages with GNU Stow
make stow        # alias for make dotfiles
make check       # Ansible syntax checks and ansible-lint when available
make doctor      # validate required commands and managed links
make verify      # checks plus obsolete-tooling guard
```

## Package Policy

System packages come only from Fedora repositories. The main groups are:

- GCC, glibc headers, CMake, Ninja, pkg-config, GDB and clangd/clang-format for C.
- `uv` for Python; `fnm` supplies Node.js and npm installs pnpm for JS/TS.
- A focused TeX Live set for mathematical writing and Beamer presentations:
  AMS packages, `mathtools`, `biblatex`/`biber`, `latexmk`, pdfLaTeX,
  XeLaTeX and LuaLaTeX.
- ShellCheck for shell scripts.
- Common shell, archive, Git and terminal utilities.

Fedora's `ncurses-term` provides terminfo entries for terminal applications.

Desktop, Wayland, audio, Bluetooth and network-management packages are left to
the host and are not installed inside the container. User fonts, MIME
associations and VS Code settings remain managed for applications installed
from the container.

The repository does not install a container engine or container tooling.

Starship, lazygit, yazi, resvg, opencode and Harlequin remain optional. The
Neovim configuration requires 0.12+ (available in Fedora 45). Add any
thesis-specific TeX packages to `fedora_packages` in `group_vars/all.yml` if
your document uses packages beyond the included mathematical and Beamer set.

The only upstream downloads automated by Ansible are:

- IBM Plex Mono Nerd Font, JetBrains Mono Nerd Font and Inter.
- A pinned `fnm` release and the configured Node.js LTS release.
- pnpm via npm in that Node.js installation.

Neovim configures Python (basedpyright and Ruff), JS/TS (vtsls) and C (clangd).
Mason supplies the Python and JS/TS language servers; Fedora supplies clangd.

The managed MIME associations expect Zen Browser, GNOME Papers and the Claude
URL handler to be installed separately.

## Stow Packages

Configuration is linked from `packages/` with `stow --no-folding`:

- `git`, `shell-container`, `starship`, `nvim-vm`
- `btop`, `tmux`, `opencode`
- `xdg` for `mimeapps.list`
- `vscode` for portable VS Code settings

Existing conflicting files are moved to a timestamped directory under
`~/.dotfiles-backup/` before Stow creates links. Generated application state,
credentials, histories, caches, databases and package locks are not managed.

## Bootstrap

Inside a Fedora container:

```sh
DOTFILES_REPO_URL="https://github.com/USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
bash bootstrap-dotfiles.sh
```

The bootstrap installs only Git, Make and Python when missing, verifies that
GNU Stow was installed manually, clones or updates the repository, and runs
`make`.
