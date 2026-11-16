#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=config.sh
source "$ROOT/scripts/config.sh"
# shellcheck source=macos.sh
source "$ROOT/scripts/macos.sh"
DRY_RUN=${DRY_RUN:-0}
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1

log() { printf '[dotfiles] %s\n' "$*"; }
die() { printf '[dotfiles] ERROR: %s\n' "$*" >&2; exit 1; }
run() {
  if [[ $DRY_RUN == 1 ]]; then
    printf '[dry-run]'; printf ' %q' "$@"; printf '\n'
  else
    "$@"
  fi
}
require_commands() {
  local name
  for name in "$@"; do
    command -v "$name" >/dev/null 2>&1 || die "Missing command: $name"
  done
}
require_macos() {
  [[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] ||
    die 'Setup requires native Apple Silicon macOS; Linux supports offline tests only.'
  ((EUID != 0)) || die 'Run as your own user, never sudo the whole setup.'
  xcode-select -p >/dev/null 2>&1 || die 'Install Command Line Tools: xcode-select --install'
  require_commands brew defaults
  HOMEBREW_PREFIX=$(brew --prefix)
  export HOMEBREW_PREFIX
  [[ $HOMEBREW_PREFIX == /opt/homebrew ]] || die 'Use native /opt/homebrew, not Rosetta Homebrew.'
  # Process-local tool lookup only; never source or edit the user's shell files.
  local directory
  for directory in "$HOMEBREW_PREFIX/bin" /Library/TeX/texbin "$HOME/.local/bin"; do
    case ":$PATH:" in *":$directory:"*) ;; *) PATH="$directory:$PATH" ;; esac
  done
  directory=$HOMEBREW_PREFIX/opt/llvm/bin
  case ":$PATH:" in *":$directory:"*) ;; *) PATH="$PATH:$directory" ;; esac
  export PATH
}
install_brew() {
  local kind=$1 package
  shift
  local missing=()
  if ! command -v brew >/dev/null 2>&1; then
    [[ $DRY_RUN == 1 ]] || die 'Homebrew is required.'
    run brew install "--$kind" "$@"
    return
  fi
  for package in "$@"; do
    if ! brew list "--$kind" --versions "$package" >/dev/null 2>&1; then
      missing+=("$package")
    fi
  done
  ((${#missing[@]})) || return 0
  run brew install "--$kind" "${missing[@]}" || die "Homebrew $kind installation failed."
}
install_packages() {
  # Never install competing TeX distributions into the same environment.
  if brew list --cask --versions basictex >/dev/null 2>&1 ||
     brew list --cask --versions mactex >/dev/null 2>&1; then
    die 'BasicTeX/full GUI MacTeX already installed; reconcile TeX ownership manually.'
  fi
  if brew list --formula --versions opencode >/dev/null 2>&1; then
    die 'A separate opencode formula is installed. Review/remove V1 before installing V2.'
  fi
  install_brew formula "${MACOS_FORMULAE[@]}"
  install_brew cask "${CORE_CASKS[@]}"
}
install_fonts() { install_brew cask "${FONT_CASKS[@]}"; }
check_neovim() {
  if [[ $DRY_RUN == 1 ]]; then
    log 'Would verify the installed Neovim is 0.12+ (no configuration is deployed).'
    return
  fi
  require_commands nvim
  nvim --clean --headless '+lua if vim.fn.has("nvim-0.12") == 0 then vim.cmd("cquit 1") end' +qa
}
install_node() {
  if [[ $DRY_RUN == 1 ]]; then
    run fnm install "$NODE_VERSION"
    run fnm default "$NODE_VERSION"
    log "Would ensure pnpm $PNPM_VERSION in the fnm runtime (not Homebrew)."
    return
  fi
  require_commands fnm
  local version node_path
  # fnm install reuses the installed runtime; it does not update every invocation.
  fnm install "$NODE_VERSION"
  fnm default "$NODE_VERSION"
  node_path=$(fnm exec --using="$NODE_VERSION" node -p 'process.execPath')
  # An unrelated Homebrew/global pnpm on PATH must not count as a runtime install.
  version=$("${node_path%/*}/pnpm" --version 2>/dev/null) || version=''
  if [[ $version != "$PNPM_VERSION".* ]]; then
    fnm exec --using="$NODE_VERSION" npm install --global "pnpm@$PNPM_VERSION"
  fi
  version=$("${node_path%/*}/pnpm" --version)
  [[ $version == "$PNPM_VERSION".* ]] || die 'pnpm is not installed in the selected fnm runtime.'
}
install_octave() {
  install_brew formula octave make
  if [[ $DRY_RUN == 1 ]]; then
    log "Would install missing user-local Octave packages: ${OCTAVE_PACKAGES[*]} specfun."
    return
  fi
  require_commands octave
  local package
  for package in "${OCTAVE_PACKAGES[@]}" specfun; do
    if ! octave --no-gui --quiet --eval "pkg load $package;" >/dev/null 2>&1; then
      if [[ $package == specfun ]]; then
        MAKE=gmake octave --no-gui --quiet --eval "pkg install -local '$SPECFUN_URL'; pkg load specfun;"
      else
        MAKE=gmake octave --no-gui --quiet --eval "pkg install -local -forge $package; pkg load $package;"
      fi
    fi
  done
}
install_apps() {
  install_brew formula "${APP_FORMULAE[@]}"
  install_brew cask "${APP_CASKS[@]}"
  log 'Open OrbStack, Screen Studio, Rnote and other apps to finish permissions/licensing/sign-in.'
}
install_app_store() {
  if command -v brew >/dev/null 2>&1 &&
     brew list --cask --versions whatsapp >/dev/null 2>&1; then
    die 'WhatsApp is Homebrew-owned; reconcile ownership before using the App Store.'
  fi
  install_brew formula mas
  if [[ $DRY_RUN == 1 ]]; then
    local entry
    for entry in "${MAS_APPS[@]}"; do run mas get "${entry%%|*}"; done
    return
  fi
  require_commands mas
  local installed entry id
  installed=$(mas list) || die 'Sign into the Mac App Store and rerun make setup.'
  for entry in "${MAS_APPS[@]}"; do
    id=${entry%%|*}
    if ! grep -Eq "^[[:space:]]*${id}[[:space:]]" <<< "$installed"; then
      log "Installing ${entry#*|}; App Store sign-in/authorization may be requested."
      mas get "$id" || die "App Store installation failed for ${entry#*|}."
    fi
  done
}
install_zathura() {
  local plugin source dest prefix
  install_brew formula "$ZATHURA_TAP/zathura"
  for plugin in "${ZATHURA_PLUGINS[@]}"; do
    install_brew formula "$ZATHURA_TAP/zathura-$plugin"
  done
  if [[ $DRY_RUN == 1 ]]; then log 'Would link Zathura native plugins; EPUB support is unverified.'; return; fi
  prefix=$(brew --prefix "$ZATHURA_TAP/zathura")
  dest=$prefix/lib/zathura
  # Refuse a second PDF backend rather than leave ambiguous loading behavior.
  [[ ! -e $dest/libpdf-poppler.dylib && ! -L $dest/libpdf-poppler.dylib ]] ||
    die 'Remove/reconcile the competing Zathura Poppler plugin manually.'
  [[ ! -L $dest ]] || die "Refusing symlinked plugin directory: $dest"
  mkdir -p "$dest"
  for plugin in "${ZATHURA_PLUGINS[@]}"; do
    source=$(brew --prefix "$ZATHURA_TAP/zathura-$plugin")/lib$plugin.dylib
    [[ -f $source ]] || die "Missing Zathura plugin: $source"
    if [[ -L $dest/lib$plugin.dylib && $dest/lib$plugin.dylib -ef $source ]]; then continue; fi
    [[ ! -e $dest/lib$plugin.dylib && ! -L $dest/lib$plugin.dylib ]] ||
      die "Conflicting Zathura plugin: $dest/lib$plugin.dylib"
    ln -s "$source" "$dest/lib$plugin.dylib"
  done
  log 'Zathura installed as a CLI; app-bundle generation is deliberately manual.'
}
check_applications() {
  local cask entry installed prefix plugin source failed=0
  for cask in "${CORE_CASKS[@]}" "${FONT_CASKS[@]}" "${APP_CASKS[@]}"; do
    if ! brew list --cask --versions "$cask" >/dev/null 2>&1; then
      log "MISS cask $cask"; failed=1
    fi
  done
  if installed=$(mas list); then
    for entry in "${MAS_APPS[@]}"; do
      if ! grep -Eq "^[[:space:]]*${entry%%|*}[[:space:]]" <<< "$installed"; then
        log "MISS App Store app ${entry#*|}"; failed=1
      fi
    done
  else
    log 'Cannot query installed App Store apps'; failed=1
  fi
  if prefix=$(brew --prefix "$ZATHURA_TAP/zathura"); then
    for plugin in "${ZATHURA_PLUGINS[@]}"; do
      if source=$(brew --prefix "$ZATHURA_TAP/zathura-$plugin") &&
         [[ -L $prefix/lib/zathura/lib$plugin.dylib &&
            $prefix/lib/zathura/lib$plugin.dylib -ef $source/lib$plugin.dylib ]]; then
        continue
      fi
      log "MISS Zathura plugin $plugin"; failed=1
    done
  else
    log 'MISS Zathura installation'; failed=1
  fi
  ((failed == 0))
}
check_tex() (
  local resource failed=0 temp
  for resource in "${TEX_RESOURCES[@]}"; do
    if ! kpsewhich "$resource"; then log "MISS TeX resource $resource"; failed=1; fi
  done
  temp=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-latex.XXXXXX")
  trap 'rm -rf -- "$temp"' EXIT
  # Disposable installation smoke test, not an application configuration/template.
  cat > "$temp/smoke.tex" <<'TEX'
\documentclass{article}
\usepackage[T1]{fontenc}
\usepackage{lmodern,geometry,microtype}
\usepackage{amsmath,amssymb,amsthm,mathtools}
\begin{document}
\(\lVert x \rVert^2 = \sum_i x_i^2\)
\end{document}
TEX
  latexmk -norc -pdf -halt-on-error -interaction=nonstopmode "-output-directory=$temp" \
    "$temp/smoke.tex" || failed=1
  ((failed == 0))
)
doctor() {
  local name path node_path version failed=0
  if node_path=$(fnm exec --using="$NODE_VERSION" node -p 'process.execPath'); then
    export PATH="${node_path%/*}:$PATH"
  else log "MISS fnm Node $NODE_VERSION"; failed=1; fi
  for name in "${EXPECTED_COMMANDS[@]}"; do
    if path=$(command -v "$name"); then printf 'OK   %-18s %s\n' "$name" "$path"
    else log "MISS command $name"; failed=1; fi
  done
  version=$(node --version) || version=''
  [[ $version == v"$NODE_VERSION".* ]] || { log 'Wrong Node major'; failed=1; }
  version=$(pnpm --version) || version=''
  [[ $version == "$PNPM_VERSION".* ]] || { log 'Wrong pnpm major'; failed=1; }
  path=$(command -v pnpm) || path=''
  [[ $path -ef ${node_path%/*}/pnpm ]] ||
    { log 'pnpm must belong to the selected fnm Node runtime'; failed=1; }
  version=$(opencode --version) || version=''
  [[ $version == 2.* ]] || { log 'Expected OpenCode V2'; failed=1; }
  python3 -c 'import sys; assert sys.version_info[:2] == (3, 13)' ||
    { log 'Expected uv-managed Python 3.13 on PATH'; failed=1; }
  for name in bash git fnm uv opencode starship; do
    path=$(command -v "$name") || path=''
    if [[ ! $path -ef $HOMEBREW_PREFIX/bin/$name ]]; then
      log "Wrong owner for $name: expected $HOMEBREW_PREFIX/bin/$name"
      failed=1
    fi
  done
  [[ $(command -v clang) -ef /usr/bin/clang ]] ||
    { log 'Expected Apple CLT clang, not a competing compiler on PATH'; failed=1; }
  bash -c '((BASH_VERSINFO[0] >= 5))' || failed=1
  check_neovim || failed=1
  check_applications || failed=1
  check_macos_preferences || failed=1
  check_tex || failed=1
  for name in "${OCTAVE_PACKAGES[@]}" specfun; do
    octave --no-gui --quiet --eval "pkg load $name;" || failed=1
  done
  octave --no-gui --quiet --eval \
    'pkg load image statistics signal specfun; assert (isequal (size (imresize (eye (2), 2)), [4 4])); assert (abs (normcdf (0) - 0.5) < 1e-12); [b,a] = butter (2, 0.2); assert (all (isfinite (filter (b,a,ones (1,8))))); assert (abs (erfcinv (1)) < 1e-12);' || failed=1
  ((failed == 0)) || die 'Doctor failed; fix the diagnostics above.'
  log 'Doctor: OK (GUI behavior, preference activation, Wacom and app onboarding still need manual checks).'
}
setup_all() {
  install_packages
  check_neovim
  install_fonts
  install_node
  run uv python install --default 3.13
  install_octave
  install_apps
  install_zathura
  install_app_store
  apply_macos_preferences
}
main() {
  ((BASH_VERSINFO[0] >= 5)) || die 'Use scripts/bash.sh with Bash 5+.'
  require_macos
  case ${1:-setup} in
    setup) setup_all ;;
    doctor) doctor ;;
    *) die "Unknown stage: $1" ;;
  esac
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
