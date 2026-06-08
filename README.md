# Portable Dotfiles

Single portable flow for shell, Git, Starship, and Neovim:

```sh
make
```

`make` installs or loads Homebrew, runs `brew bundle`, applies the portable
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
- Daily CLI: tree, fd, ripgrep, fzf, bat, btop, duf, ncdu, tmux, fastfetch.
- Neovim tooling: Neovim, tree-sitter, Lua, Stylua.
- Toolchains and managers: uv, fnm, juliaup, pnpm, Go, Rust via official
  rustup installer, Zig, LLVM, OpenJDK, Gradle.
- Prompt and dotfile helpers: Starship and GNU Stow. `stown` is installed by
  Ansible with Python only when it is not already available.

Neovim's Node-based LSP/formatter tools are installed globally with `pnpm`,
not through Mason's npm backend.

`make brew` runs Homebrew Bundle with parallel jobs by default. Override with
`BREW_BUNDLE_JOBS=1 make brew` if a formula needs sequential installation.

## Dotfiles

Packages are linked from `packages/` with `stown`:

- `git`
- `shell-container`
- `starship`
- `nvim-vm`

Shell files use portable Homebrew detection for:

- `/opt/homebrew/bin/brew`
- `/usr/local/bin/brew`
- `/home/linuxbrew/.linuxbrew/bin/brew`

Fonts install into `~/.local/share/fonts/nerd-fonts`, keeping them user-local
and portable across Linux and macOS.

## Bootstrap

`bootstrap-dotfiles.sh` is for a fresh machine:

```sh
DOTFILES_REPO_URL="https://github.com/USER/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
bash bootstrap-dotfiles.sh
```

It installs or loads Homebrew, ensures `git`, `make`, and `python3`, clones or
updates the repo, then runs `make`.
