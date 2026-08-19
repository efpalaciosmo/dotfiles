# Fedora Silverblue laptop dotfiles

A dotfile setup for a Fedora-installed Niri laptop session and Homebrew-managed
terminal tools. The repository never invokes Fedora's package manager and does
not install graphical or session software: it only configures and validates it.

```sh
make
```

`make` installs or loads Homebrew, applies the `Brewfile`, creates the local
Ansible environment, links every package with GNU Stow, and validates the repo.

## Commands

```sh
make                  # same as make setup
make setup            # Homebrew, dotfiles, fonts, shell tools, and validation
make brew             # install/load Homebrew and apply Brewfile
make fonts            # install user-local fonts
make shell            # install Oh My Zsh and its configured plugins
make dotfiles         # link dotfiles with GNU Stow
make stow             # dotfiles plus shell configuration
make check            # non-mutating static checks
make doctor           # commands, Homebrew, and symlink diagnostics
make verify           # all static checks and repository guards
make node-user-tools  # install configured pnpm global tools
```

Use `DRY_RUN=1 make` for Homebrew Bundle's check plus Ansible check mode. Use
`BREW_BUNDLE_JOBS=1 make brew` if a formula must be installed sequentially.
No Ansible task requires sudo.

## Package ownership

- `Brewfile` contains only terminal, CLI, compiler, and development tools.
- Niri, Waybar, Rofi, Ghostty, Mako, swaybg, swaylock, wl-clipboard, cliphist,
  playerctl, brightnessctl, and libnotify must be installed manually from
  Fedora. They are intentionally absent from `Brewfile`.
- GNU Stow, installed by Homebrew, is the only dotfile linker.
- Rust is the Homebrew `rust` formula; Node is the Homebrew `node` formula.
- Standard `ffmpeg` and `imagemagick` formulas are used instead of `*-full`
  variants to avoid unnecessary library graphs and keg-link conflicts.
- No distribution package-manager workflow is present.

`make doctor` checks both groups: Brew-provided terminal commands
and the Fedora-provided session runtime. The configuration is laptop-specific:
only the internal `eDP-1` panel is customized and battery/brightness controls
are enabled.

Static checks can run outside the graphical session, but they cannot prove that
the compositor, portals, audio, brightness, or hardware integration work on the
target laptop. After installing the Fedora session packages and applying these
dotfiles, log into Niri and run `make doctor`; that is the required final machine
check and intentionally fails when a runtime command, config, or link is broken.

## Dotfile packages

The packages under `packages/` are linked into `$HOME`:

- `git`
- `shell-container`
- `starship`
- `nvim-vm`
- `ghostty`
- `niri`
- `waybar`
- `mako`
- `rofi`

Ghostty is the only terminal used by Niri, Rofi, and Waybar helpers.

## Fresh installation

```sh
DOTFILES_REPO_URL="https://github.com/USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
bash bootstrap-dotfiles.sh
```

The bootstrap script installs Homebrew with its official installer, ensures
`git`, `make`, and Python are available from Brew, clones or updates this repo,
and runs `make`. Re-run `make doctor` after logging into Niri to check command
resolution and every managed symlink.
