# Developer tools

Everything here uses the desktop palette from [Adwaita theme](adwaita-theme.md): surface
`#1d1d20`, raised `#36363a`, selected row `#4b4b50`, accent `#ff7800`, text orange `#ff9c5b`,
JetBrainsMono Nerd Font. Packages are linked by `make` like the others.

| Package | Links | What you get |
| --- | --- | --- |
| `vi` | `~/.vimrc`, `~/.vim/colors/adwaita-orange.vim` | Vim options plus the Adwaita-orange colorscheme. |
| `fastfetch` | `~/.config/fastfetch/config.jsonc` | System / Desktop / Hardware / Appearance sections with Nerd Font icons and orange accents. |
| `btop` | `~/.config/btop/btop.conf`, `themes/adwaita-orange.theme` | Same palette, vi keys. btop may rewrite `btop.conf` when you change settings inside it. |
| `shell-container` | `~/.zshrc`, `~/.bashrc`, `~/.profile` | Zsh with Oh My Zsh, `zsh-autosuggestions` and `zsh-syntax-highlighting` under `~/.oh-my-zsh`, plus Starship (see below). |
| `claude` | `~/.claude/settings.json`, `CLAUDE.md`, `statusline.sh`, `hooks/notify.sh` | See below. |
| `opencode` | `~/.config/opencode/opencode.json`, `cli.json`, `themes/adwaita-orange.json` | Theme, read-only permission rules, update notices. |
| `git` | `~/.gitconfig` | Sensible defaults (`push.autoSetupRemote`, `merge.conflictStyle=zdiff3`, `rerere`, aliases `st lg last undo`). |

## Zsh, Oh My Zsh and plugins

`make` runs `scripts/install-zsh.sh` whenever `shell-container` is linked. It clones Oh My Zsh,
`zsh-autosuggestions` and `zsh-syntax-highlighting` into `~/.oh-my-zsh` with plain `git`: no
package manager and no `rpm-ostree` layering, so it works on the immutable host and in the
Distrobox (the home directory is shared). If you are offline, the links are still created and the
script reports what is missing; run `make` again later.

- Each repository is pinned to a commit in the script, because this code runs in every shell.
  To update, change the SHAs at the top of `scripts/install-zsh.sh` and run `make`.
  The installer never overwrites a directory that is not a Git checkout or has local edits.
- `zstyle ':omz:update' mode disabled` in `.zshrc` stops `omz update` from fighting the pins.
- `make doctor` reports `MISS zsh ...` when any of the three is absent.

## Claude Code

- **Theme `dark-ansi`.** A custom Claude *look* (`$.theme.set`) only draws in the desktop and
  mobile apps, never in a terminal. `dark-ansi` makes the terminal UI use Ghostty's ANSI palette,
  so it follows the Adwaita palette automatically.
- **Status line** (`statusline.sh`): directory, Git branch (`*` when dirty), model and context
  usage colored green/amber/red at 60% and 85%. Requires `jq`.
- **Notifications** (`hooks/notify.sh`): a Mako notification titled `Claude Code · <project>`
  when Claude needs attention (permission prompt, long wait). It honors do-not-disturb
  (`Super+Shift+Z`).
- **Permissions:** read-only Git/`make check`/`niri validate` are pre-approved; credential
  files (`.credentials.json`, opencode `service.json`, `~/.ssh`, `~/.gnupg`, `.env*`) are denied.
- **`CLAUDE.md`** holds global preferences (language, environment, working style, secrets).
  opencode reads it too when it has no `AGENTS.md`.
- Claude Code may replace the `settings.json` link with a regular file when it saves settings.
  Run `make PACKAGES=claude` again to relink; the file's content is the same.

## opencode

The theme uses opencode's V2 format (`base` token tree plus a `dark` hue palette with the
required `accent`, `interactive` and `neutral` hues). It is selected in `cli.json`, not in
`opencode.json`. opencode skips an invalid theme and shows `Failed to load theme` instead of
crashing; check `~/.local/share/opencode/log` for `configuration normalization diagnostic` lines
after editing `opencode.json`.

`~/.config/opencode/service.json` contains the background service password. It is **not** part of
the repository and is ignored by `.gitignore`; do not add it.

opencode has previously edited `~/.gitconfig` (which is a link into this repository) to add a GitHub
credential helper under `/tmp/opencode/...`. That path disappears, so it was removed. Review
`git diff` after running opencode's GitHub integrations, and use `gh auth setup-git` where the
GitHub CLI is installed.

## Editors

Vim is the editor (`EDITOR`/`VISUAL` are `vim`). Neovim and tmux are intentionally not
configured; the Fedora Distrobox shares the home directory, so the same Vim setup applies there.
Without 24-bit color the Vim theme steps aside so the terminal's own ANSI palette applies.

## Checks

`make check` validates every JSON file, runs `fastfetch` against its config and loads the
colorscheme in Vim without messages. `scripts/validate-configs.sh fastfetch vi` runs those two
alone.
