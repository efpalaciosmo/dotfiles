# Fedora Distrobox Dotfiles

Bash installs packages from the official Fedora repositories, configures
user-local tools and links configuration files with GNU Stow. Setup does not
require Python or a virtual environment.

## Setup

Run inside Fedora Workstation or a Fedora container, such as
`distrobox enter fedora`, with working passwordless `sudo`:

```sh
sudo -n true
make setup
```

The default setup installs missing Fedora packages without weak dependencies,
installs fnm, Node.js and pnpm, installs fonts, applies Stow packages, checks
scripts and validates commands, links, TeX resources and a LaTeX template build.
Syntax and lint checks run before setup changes anything. Only DNF requires
privilege escalation. Setup stops on the first failed step;
fix the error and rerun it.

Preview without installing, downloading, backing up or linking anything:

```sh
DRY_RUN=1 make setup
```

Stow simulates packages without conflicts. For packages with conflicts, the
preview reports the backups and linking that would occur.

## Commands

```sh
make setup       # full setup and validation (also the default target)
make packages    # install missing Fedora packages
make fonts       # install pinned user-local fonts
make fnm         # install fnm, Node.js LTS and pnpm
make shell-check # test interactive Bash → zsh → Starship startup
make dotfiles    # back up conflicts and link configuration with GNU Stow
make stow        # alias for make dotfiles
make doctor      # validate commands, links and TeX resources; build LaTeX template
make check       # Bash syntax checks and ShellCheck when installed
make test        # offline regression and startup tests (requires installed tools)
make verify      # syntax checks and obsolete-tooling guard
```

Package lists, required and optional commands, upstream versions and font
checksums live in `scripts/config.sh`. Setup functions live in
`scripts/setup.sh`. Individual install targets assume their tools have already
been installed with `make packages`.

## Package policy

System packages come from Fedora repositories, except Starship, which uses
the `atim/starship` COPR repository recommended by its upstream Fedora guide.
Setup enables that repository when Starship is missing, then installs it with
DNF. Setup installs `dnf5-plugins` first if the COPR plugin is missing. The main groups are:

- GCC, glibc headers, CMake, Ninja, pkg-config, GDB and clang tools for C.
- `uv` for Python development; fnm supplies Node.js, and npm installs pnpm.
- A focused TeX Live set for mathematical writing and Beamer presentations,
  including AMS packages, mathtools, biblatex/biber, latexmk, pdfLaTeX,
  XeLaTeX and LuaLaTeX.
- Starship, GNU Stow, ShellCheck and common shell, archive, Git and terminal utilities.

Desktop, Wayland, audio, Bluetooth and network-management packages are left to
the host. This repository does not install a container engine or container
tooling. Fedora's `ncurses-term` supplies terminal terminfo entries.

Lazygit, yazi, resvg, opencode and Harlequin remain optional because
they are not supplied by the enabled official Fedora repositories. Neovim
requires 0.12+ (available in Fedora 45). Add document-specific TeX packages to
`FEDORA_PACKAGES` in `scripts/config.sh`.

Upstream downloads are limited to checksum-verified font archives (IBM Plex Mono
Nerd Font, JetBrains Mono Nerd Font and Inter), a checksum-verified fnm release,
Node.js installed by fnm, and pnpm installed by npm. Downloads are cached under
`${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles`; completed fonts use installation
markers to avoid extracting the same version again.

## Dotfiles

Configuration is linked from `packages/` with `stow --no-folding`:

- `git`, `shell-container`, `starship`, `nvim-vm`
- `btop`, `opencode`
- `xdg` for MIME associations and the Papers desktop entry

Conflicts, including broken links, move to a timestamped directory under
`~/.dotfiles-backup/<timestamp>-<pid>/` before Stow creates links. Backup paths
mirror the original paths under your home directory (for example, `.bashrc`
or `.config/nvim/init.lua`). Backup directories are private to your user, and
an existing backup is never overwritten. These are backups of conflicts;
files already linked to this checkout do not create redundant backups. Conflicting parent files or
directory symlinks are backed up before creating directories. Generated state,
credentials, caches, databases and package locks are ignored. Doctor verifies
that managed links resolve to files in this checkout. It also tests interactive
Bash → zsh → Starship startup in a temporary home directory and renders the
configured prompt. Startup checks time out after 30 seconds and preserve
diagnostics when they fail.

To restore a file, remove only its managed symlink, then move the matching
file from the backup directory to its original path. Backups are retained
until you remove them.

Interactive Bash sessions in the Fedora Distrobox switch directly to zsh.
Non-interactive commands stay in their original shell. Open a new terminal
or run `exec zsh -l` after updating. Neovim, Starship and btop use the Adwaita
Dark palette. Ctrl-h/j/k/l in Neovim navigate its splits.

Neovim configures Python (basedpyright and Ruff), JS/TS (vtsls) and C (clangd).
Mason supplies the Python and JS/TS language servers; Fedora supplies clangd.
The MIME associations expect Zen Browser, GNOME Papers and the Claude URL
handler to be installed separately.

## Bootstrap

Inside a Fedora container:

```sh
DOTFILES_REPO_URL="https://github.com/USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
bash bootstrap-dotfiles.sh
```

Bootstrap installs only Git and Make when missing, clones or updates the
repository and runs `make`. All other Fedora packages, including GNU Stow,
are listed in `scripts/config.sh`.
