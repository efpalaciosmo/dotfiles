# Fedora Silverblue Dotfiles

Single Fedora Silverblue flow for shell, Git, Starship, and Neovim:

```sh
make
```

`make` installs or loads Homebrew, runs `brew bundle`, applies the Fedora
Ansible workflow, and validates the repo. The Ansible profile is internal; no
profile argument is needed.

## Commands

```sh
make            # same as make setup
make setup      # Homebrew + Brewfile + fonts + shell plugins + stown dotfiles + validation
make brew       # install/load Homebrew and run brew bundle
make fonts      # install user-local fonts
make shell      # install oh-my-zsh and zsh plugins
make dotfiles   # install stown if needed and link dotfiles
make check      # syntax checks
make doctor     # command and symlink diagnostics
make verify     # syntax checks plus residue guard
make node-user-tools # install Neovim Node tooling with pnpm
```

For a non-mutating check of the Ansible work:

```sh
DRY_RUN=1 make
```

In dry-run mode, the Homebrew step uses `brew bundle check` and Ansible runs
with `--check`; it exits non-zero when Brewfile formulas are missing.

## Homebrew

`Brewfile` owns the CLI base:

- Shell and dev tools: Bash, Bash completion, Zsh, Git, GitHub CLI, build
  tools, curl/wget, archives, and JSON tools.
- Daily CLI: tree, fd, ripgrep, fzf, bat, btop, duf, ncdu, tmux, zoxide,
  fastfetch, lazygit, lazydocker, yazi, and related CLI helpers.
- Neovim tooling: Neovim, tree-sitter, Lua, Stylua, ShellCheck, and shfmt.
- Writing/media tooling: TeX Live, Poppler, ImageMagick Full, and FFmpeg Full.
- Toolchains and managers: uv, fnm, Node, pnpm, juliaup, Rust via the official
  rustup installer, Zig, LLVM, and Python for Ansible.
- Prompt and dotfile helpers: Starship and GNU Stow. `stown` is installed by
  Ansible with Python only when it is not already available.

Neovim's Node-based LSP/formatter tools are installed globally with `pnpm`,
not through Mason's npm backend.

`make brew` runs Homebrew Bundle with parallel jobs by default. Override with
`BREW_BUNDLE_JOBS=1 make brew` if a formula needs sequential installation.

Ansible does not ask for the sudo/become password by default. Use
`ASK_BECOME_PASS=1 make setup` only if you add or run tasks that explicitly
need elevated privileges.

Homebrew bootstrap has one owner: `scripts/ensure-homebrew.sh`. `make` calls it
through `scripts/with-homebrew.sh` so commands see Homebrew's PATH. The
standalone `bootstrap-dotfiles.sh` keeps a tiny copy of the same Homebrew
bootstrap logic because it may run before this repo exists on a fresh machine.

## Dotfiles

Packages are linked from `packages/` with `stown`:

- `git`
- `shell-container`
- `starship`
- `nvim-vm`

Shell files use Homebrew detection for:

- `/home/linuxbrew/.linuxbrew/bin/brew`
- `/opt/homebrew/bin/brew`
- `/usr/local/bin/brew`

Font archives are kept under `~/.local/share/fonts/nerd-fonts`, and the font
files are copied into `~/.local/share/fonts` for native font discovery on Linux.

## Bootstrap

`bootstrap-dotfiles.sh` is for a fresh machine:

```sh
DOTFILES_REPO_URL="https://github.com/USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
bash bootstrap-dotfiles.sh
```

It installs or loads Homebrew, ensures `git`, `make`, and `python3`, clones or
updates the repo, then runs `make`.
