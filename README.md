# macOS workstation setup

One command installs the selected software and applies approved macOS
preferences on Apple Silicon:

```sh
make setup
```

`make` does the same thing. This is an **installer, not a dotfile manager**.
It does not store or deploy application configurations, manage shell startup
files, set Git identity, select your editor, or configure Neovim/plugins.
There is no Stow or home-directory symlink/backup workflow.

## Prerequisites

Use a native arm64 terminal, not Rosetta.

1. Run `xcode-select --install`, wait for completion, then `xcode-select -p`.
2. Install Homebrew deliberately using <https://docs.brew.sh/Installation>.
3. Initialize Homebrew and install the automation interpreter:

   ```sh
   eval "$(/opt/homebrew/bin/brew shellenv)"
   brew install bash
   ```

Sign into the Mac App Store before setup. Never run the entire setup with sudo.
MacTeX's installer and `mas` may request their own administrator/account
authorization. Some applications require separate licensing or onboarding.

```sh
DRY_RUN=1 make setup    # preview every installation and preference change
make setup             # install everything and apply macOS preferences
make doctor            # validate installations, runtimes and preferences
make test              # offline regression tests; no installations or real defaults writes
```

Setup stops on errors. Fix the reported problem and rerun `make setup`;
installed packages, runtime tools and matching preferences are reused.
It is not an all-or-nothing transaction and does not automatically roll back.

## Installed software

Package lists are in `scripts/config.sh`; Homebrew owns formulae and casks.
No curl-to-shell installers or second Brewfile ownership model are used.

- **Editors/terminal:** Neovim 0.12+, VS Code, Ghostty.
- **CLI tools:** Git, GitHub CLI, Starship, Bash/completion, Zsh plugins,
  jq, xz, 7-Zip, tree, fd, ripgrep, fzf, bat, btop, zoxide, duf, ncdu,
  Fastfetch and ShellCheck.
- **Build tools:** CMake, Ninja, pkgconf, LLVM analysis tools and GNU Make.
  Apple's Clang/LLDB/SDK come from Command Line Tools.
- **Runtime managers:** uv and fnm are required Homebrew formulae.
  fnm owns Node 24; npm installs pnpm 10 inside that runtime, not through
  Homebrew. uv installs a default user-local Python 3.13.
- **Numerical work:** Octave plus user-local image, statistics, control,
  signal and archived specfun 1.1.0. GNU Make is used explicitly for add-on
  builds. specfun may shadow modern core functions when loaded; it is not
  automatically loaded by this installer.
- **TeX:** full `mactex-no-gui`, including the previous engines, math/layout,
  Beamer, biblatex/biber and latexmk packages. No Skim, BasicTeX or separately
  versioned biber.
- **Fonts:** IBM Plex Mono Nerd Font, JetBrains Mono Nerd Font and Inter,
  owned by their Homebrew casks. Choose your terminal font yourself.
- **OpenCode:** official `anomalyco/tap/opencode-v2` formula, no managed
  OpenCode settings or credentials. Review an existing V1 installation
  manually rather than silently removing it.
- **Applications:** Telegram, LocalSend, LibreOffice, Discord, Obsidian,
  Screen Studio, Raycast, OrbStack, Zen Browser, Brave, ChatGPT, Bruno, Zotero,
  OneDrive and Rnote.
- **Media/documents:** mpv CLI and Zathura with MuPDF, DjVu, PostScript and
  comic plugins.
- **Mac App Store:** WhatsApp and Amphetamine via `mas get`, included in setup.
  Account authentication/Touch ID may be requested. Store availability varies
  by region; Spotlight indexing is required to detect installed Store apps.

Rust, Julia, Zig, Linux containers and Wacom drivers are not installed.
Check your Wacom model's driver compatibility manually, then approve required
permissions/restarts yourself.

Formulae/casks track Homebrew releases rather than the old Linux asset pins.
Setup disables Homebrew auto-update and does not routinely upgrade everything.
Update deliberately with `brew update` / `brew upgrade`, then rerun setup.
Existing packages or environments are not automatically uninstalled.

### Zathura

The explicitly selected third-party tap is
[`homebrew-zathura/zathura`](https://github.com/homebrew-zathura/homebrew-zathura).
Its documented plugin-library links are created **inside Homebrew**, solely
to complete plugin installation—not under `~/.config`.
Existing conflicting libraries and a competing Poppler PDF backend cause an
error rather than an overwrite.

No app-bundle conversion script is downloaded/executed. Zathura is installed
as a CLI; EPUB support is unverified. Test actual document rendering and any
SyncTeX/inverse-search workflow yourself.

## macOS preferences

`make setup` applies only the preferences selected for this workstation,
using per-user `defaults` commands:

| Area | Changes |
| --- | --- |
| Finder visibility | Show filename extensions, hidden files, path bar and status bar |
| Finder navigation | Folders first in name-sorted views; search the current folder |
| Dock | Auto-hide; hide recent-app suggestions |
| Screenshots | PNG files in `~/Pictures/Screenshots` |
| Typing | Disable smart quotes, smart dashes and automatic spelling correction |
| Trackpad | Enable tap-to-click for built-in and Bluetooth trackpads |

Values are read before writing; matching values are left alone. Only the
screenshot directory is created for these preferences. No Finder/Dock restart
is forced; **log out and back in** to activate all changes. Some applications
override system typing preferences. macOS versions or managed-device policies
can affect support; doctor checks stored values, not live GUI behavior.

Keyboard layout/repeat, natural scrolling, security/privacy protections,
default applications and login items remain untouched.

## Your application and shell configurations

Configure applications yourself. The installer never writes `.zshrc`,
`.zprofile`, `.bashrc`, `.profile`, `.gitconfig` or `~/.config/*`.
It does not install VS Code extensions or Neovim plugins/parsers/LSP tools.
Credentials and app data are not copied.

Homebrew, LLVM, TeX and user-local executable paths are initialized only for
the setup/doctor process; no persistent shell environment is managed.
For example, to activate fnm in your **current** Zsh terminal:

```sh
eval "$(fnm env --use-on-cd --shell zsh)"
```

If you want this in future terminals, configure your shell yourself using
fnm's documentation. Starship/Zoxide/completion also require your own shell
initialization. uv's user-local executables normally use `~/.local/bin`;
make that available in your own environment as appropriate.

The old `packages/` configurations have been removed from this repository.
Existing home files and symlinks are not removed or repaired. If an older
deployment linked into this repository's deleted files, those links may now
be dangling; review them manually. Existing backups are left untouched.

## Verification and bootstrap

- `make check`: Bash syntax, ShellCheck when available, obsolete-tooling guard.
- `make verify` / `make test`: isolated installer and preference regression tests.
- `make doctor`: command/ownership/version checks, casks and Store apps,
  Zathura plugin links, TeX resources and a disposable compilation smoke test,
  Octave package/numerical checks, and selected macOS preference values.

All checks avoid application configuration deployment. Tests run on Linux
or macOS using mocked package managers/`defaults`; they do not prove native
installations, GUI behavior, hardware support or preference activation.
Those checks must be performed on the Mac. Neovim probes use `--clean` and
do not load your configuration.

`scripts/bash.sh` selects Homebrew Bash 5+ on macOS. Apple Make runs tasks;
GNU Make is used explicitly only for Octave builds. No global GNU utility
PATH override or shell change is made.

A reviewed copy of `bootstrap-dotfiles.sh` can clone the intended branch:

```sh
DOTFILES_REPO_URL="https://github.com/OWNER/REPOSITORY.git" \
DOTFILES_BRANCH="YOUR_MACOS_BRANCH" \
/bin/bash bootstrap-dotfiles.sh
```

Historical script/environment names remain for compatibility. The destination
defaults to `~/Projects/dotfiles_mac`. Existing checkouts update only with
`DOTFILES_UPDATE=1`, require a clean working tree and permit fast-forward
updates only. `DRY_RUN=1` prints clone/update/setup operations without executing.
