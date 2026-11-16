#!/usr/bin/env bash
# Offline installer tests: isolated HOME; package managers and macOS defaults mocked.
set -Eeuo pipefail
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/mac-setup-test.XXXXXX")
TEST_ROOT=$(cd -- "$TEST_ROOT" && pwd -P)
trap 'rm -rf -- "$TEST_ROOT"' EXIT
export HOME=$TEST_ROOT/home XDG_CACHE_HOME=$TEST_ROOT/cache
mkdir -p "$HOME/.config/nvim" "$HOME/.config/ghostty"
printf 'existing shell settings\n' > "$HOME/.zshrc"
printf 'existing Git settings\n' > "$HOME/.gitconfig"
printf 'existing editor settings\n' > "$HOME/.config/nvim/init.lua"
printf 'existing terminal settings\n' > "$HOME/.config/ghostty/config"
snapshot_home() { find "$HOME" -type f -exec shasum -a 256 {} \; | sort; }
before_home=$(snapshot_home)
# shellcheck source=../scripts/setup.sh
source "$REPO/scripts/setup.sh"

# Only missing formulae/casks are installed; previews cannot mutate package state.
brew() {
  case $1 in
    list) [[ ${*: -1} == present ]] ;;
    install) printf '%s\n' "$*" >> "$TEST_ROOT/brew-calls" ;;
    *) return 1 ;;
  esac
}
DRY_RUN=1
install_brew formula present missing
install_brew cask present missing-font
[[ ! -e $TEST_ROOT/brew-calls ]]
DRY_RUN=0
install_brew formula present missing
install_brew cask present missing-font
[[ $(sed -n '1p' "$TEST_ROOT/brew-calls") == 'install --formula missing' ]]
[[ $(sed -n '2p' "$TEST_ROOT/brew-calls") == 'install --cask missing-font' ]]
install_brew formula present
(( $(wc -l < "$TEST_ROOT/brew-calls") == 2 ))
FONT_CASKS=(present)
install_fonts
(( $(wc -l < "$TEST_ROOT/brew-calls") == 2 ))
brew() { [[ $1 == list ]] && return 1; return 7; }
if (install_brew formula missing); then echo 'FAIL: swallowed installation error' >&2; exit 1; fi
unset -f brew

# pnpm must belong to fnm's Node, not an unrelated global executable.
mkdir -p "$TEST_ROOT/node/bin" "$TEST_ROOT/bin"
printf '#!/usr/bin/env bash\nprintf "10.1.0\\n"\n' > "$TEST_ROOT/bin/pnpm"
chmod +x "$TEST_ROOT/bin/pnpm"
export PATH="$TEST_ROOT/bin:$PATH"
fnm() {
  case $1 in
    install|default) printf '%s\n' "$*" >> "$TEST_ROOT/node-calls" ;;
    exec)
      shift 2
      case $1 in
        node) printf '%s/node/bin/node\n' "$TEST_ROOT" ;;
        npm)
          printf '%s\n' "$*" >> "$TEST_ROOT/npm-calls"
          printf '#!/usr/bin/env bash\nprintf "10.1.0\\n"\n' > "$TEST_ROOT/node/bin/pnpm"
          chmod +x "$TEST_ROOT/node/bin/pnpm" ;;
        *) return 1 ;;
      esac ;;
    *) return 1 ;;
  esac
}
DRY_RUN=1
install_node
[[ ! -e $TEST_ROOT/node-calls ]]
DRY_RUN=0
install_node
install_node
[[ $(cat "$TEST_ROOT/npm-calls") == 'npm install --global pnpm@10' ]]
unset -f fnm

# App Store queries tolerate indented rows and reuse installed applications.
brew() { [[ $1 == list && ${*: -1} == mas ]]; }
mas() {
  case $1 in
    list)
      printf '  310633997 WhatsApp (1.0)\n'
      if [[ -f $TEST_ROOT/mas-installed ]]; then printf '937984704 Amphetamine (1.0)\n'; fi ;;
    get)
      printf '%s\n' "$*" >> "$TEST_ROOT/mas-calls"
      touch "$TEST_ROOT/mas-installed" ;;
    *) return 1 ;;
  esac
}
install_app_store
install_app_store
[[ $(cat "$TEST_ROOT/mas-calls") == 'get 937984704' ]]
unset -f brew mas

# Zathura's required plugin links live in Homebrew, never in application dotfiles.
source "$REPO/scripts/setup.sh"
brew() {
  case $1 in
    list) [[ ${*: -1} != "${missing_cask:-}" ]] ;;
    --prefix) printf '%s\n' "$TEST_ROOT/brew/${2##*/}" ;;
    *) return 1 ;;
  esac
}
for plugin in "${ZATHURA_PLUGINS[@]}"; do
  mkdir -p "$TEST_ROOT/brew/zathura-$plugin"
  touch "$TEST_ROOT/brew/zathura-$plugin/lib$plugin.dylib"
done
install_zathura
install_zathura
for plugin in "${ZATHURA_PLUGINS[@]}"; do
  [[ $TEST_ROOT/brew/zathura/lib/zathura/lib$plugin.dylib -ef $TEST_ROOT/brew/zathura-$plugin/lib$plugin.dylib ]]
done
mas() {
  [[ $1 == list ]] || return 1
  local entry
  for entry in "${MAS_APPS[@]}"; do
    if [[ ${entry%%|*} != "${missing_store_app:-}" ]]; then
      printf '  %s %s (1.0)\n' "${entry%%|*}" "${entry#*|}"
    fi
  done
}
check_applications
missing_cask=onedrive
if check_applications; then echo 'FAIL: ignored missing cask' >&2; exit 1; fi
unset missing_cask
missing_store_app=937984704
if check_applications; then echo 'FAIL: ignored missing Store app' >&2; exit 1; fi
unset missing_store_app
rm "$TEST_ROOT/brew/zathura/lib/zathura/libcb.dylib"
if check_applications; then echo 'FAIL: ignored missing plugin link' >&2; exit 1; fi
install_zathura
check_applications
unset -f mas
touch "$TEST_ROOT/brew/zathura/lib/zathura/libpdf-poppler.dylib"
if (install_zathura); then echo 'FAIL: allowed competing PDF backends' >&2; exit 1; fi
unset -f brew

# Neovim's installation probe must propagate errors and avoid user configuration.
nvim() { return 1; }
if check_neovim; then echo 'FAIL: ignored failed Neovim version check' >&2; exit 1; fi
nvim() { printf '%s\n' "$*" > "$TEST_ROOT/nvim-probe"; }
check_neovim
[[ $(cat "$TEST_ROOT/nvim-probe") == '--clean --headless '* ]]
unset -f nvim

# Preview the real complete workflow. Only read-only queries may execute.
(
  DRY_RUN=1
  brew() { [[ $1 != list ]] && { echo 'FAIL: mutated brew during preview' >&2; exit 1; }; return 1; }
  # Called by preference_matches/apply_macos_preferences in the sourced macOS module.
  # shellcheck disable=SC2329
  defaults() { [[ $1 != read ]] && { echo 'FAIL: mutated preferences during preview' >&2; exit 1; }; return 1; }
  nvim() { echo 'FAIL: launched Neovim during preview' >&2; exit 1; }
  # Indirectly invoked through run "$@" if the dry-run guard regresses.
  # shellcheck disable=SC2329
  uv() { echo 'FAIL: executed uv during preview' >&2; exit 1; }
  fnm() { echo 'FAIL: executed fnm during preview' >&2; exit 1; }
  octave() { echo 'FAIL: executed octave during preview' >&2; exit 1; }
  mas() { echo 'FAIL: executed mas during preview' >&2; exit 1; }
  setup_all
) > "$TEST_ROOT/setup-preview"
for text in ' neovim ' ' uv ' ' fnm ' 'uv python install --default 3.13' \
  'brew install --cask telegram' 'mas get 310633997' 'mas get 937984704' \
  'homebrew-zathura/zathura/zathura-pdf-mupdf' 'defaults write com.apple.dock autohide -bool true'; do
  grep -Fq "$text" "$TEST_ROOT/setup-preview"
done
[[ $(snapshot_home) == "$before_home" && ! -e $SCREENSHOT_DIR && ! -e $HOME/.cache ]]
for name in neovim uv fnm; do [[ " ${MACOS_FORMULAE[*]} " == *" $name "* ]]; done
[[ " ${MACOS_FORMULAE[*]} " != *' stow '* ]]
if declare -F apply_dotfiles >/dev/null; then echo 'FAIL: dotfile deployment remains' >&2; exit 1; fi

# A filesystem-backed defaults mock models reads, typed writes and repeated runs.
# shellcheck disable=SC2329
defaults() {
  local path=$TEST_ROOT/preferences/$2/$3 value
  case $1 in
    read) [[ -f $path ]] || return 1; cat "$path" ;;
    write)
      value=$5
      case $4 in
        -bool) if [[ $value == true ]]; then value=1; else value=0; fi ;;
        -string) ;;
        *) return 1 ;;
      esac
      mkdir -p "$(dirname -- "$path")"
      printf '%s\n' "$value" > "$path"
      printf '%s\n' "$*" >> "$TEST_ROOT/preference-writes" ;;
    *) return 1 ;;
  esac
}
DRY_RUN=0
apply_macos_preferences
check_macos_preferences
[[ -d $SCREENSHOT_DIR ]]
(( $(wc -l < "$TEST_ROOT/preference-writes") == ${#MACOS_DEFAULTS[@]} ))
apply_macos_preferences
(( $(wc -l < "$TEST_ROOT/preference-writes") == ${#MACOS_DEFAULTS[@]} ))
printf '0\n' > "$TEST_ROOT/preferences/com.apple.dock/autohide"
if check_macos_preferences; then echo 'FAIL: ignored preference drift' >&2; exit 1; fi
apply_macos_preferences
(( $(wc -l < "$TEST_ROOT/preference-writes") == ${#MACOS_DEFAULTS[@]} + 1 ))
check_macos_preferences
[[ $(cat "$TEST_ROOT/preferences/com.apple.screencapture/location") == "$SCREENSHOT_DIR" ]]
[[ $(cat "$TEST_ROOT/preferences/NSGlobalDomain/NSAutomaticSpellingCorrectionEnabled") == 0 ]]
[[ $(cat "$TEST_ROOT/preferences/com.apple.AppleMultitouchTrackpad/Clicking") == 1 ]]
# Called by the sourced module to exercise write-failure propagation.
# shellcheck disable=SC2329
defaults() { [[ $1 == read ]] && return 1; return 9; }
if (apply_macos_preferences); then echo 'FAIL: swallowed preference write error' >&2; exit 1; fi
unset -f defaults

# No tests or preference deployment may edit existing application/shell/Git files.
[[ $(snapshot_home) == "$before_home" ]]
[[ ! -L $HOME/.config/nvim/init.lua && ! -L $HOME/.zshrc && ! -e $HOME/.dotfiles-backup ]]
if [[ $(uname -s) != Darwin ]]; then
  if "$BASH" "$REPO/scripts/setup.sh" setup; then echo 'FAIL: Linux install allowed' >&2; exit 1; fi
fi
printf 'Offline installer and macOS preference tests: OK\n'
