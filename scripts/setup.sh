#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=config.sh
source "$ROOT/scripts/config.sh"
DRY_RUN=${DRY_RUN:-0}
CACHE_ROOT=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles
BACKUP_ROOT=$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)-$$
export PATH="$HOME/.local/bin:$PATH"

log() { printf '[dotfiles] %s\n' "$*"; }
die() { printf '[dotfiles] ERROR: %s\n' "$*" >&2; exit 1; }
run() {
  if [[ $DRY_RUN == 1 ]]; then
    printf '[dry-run]'; printf ' %q' "$@"; printf '\n'
  else
    "$@"
  fi
}
require_fedora() {
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ ${ID:-} == fedora && ${VARIANT_ID:-} =~ ^(workstation|container)$ ]] ||
    die 'Run setup inside Fedora Workstation or a Fedora container.'
}
require_commands() {
  local name
  for name in "$@"; do
    command -v "$name" >/dev/null 2>&1 || die "Missing $name; run make packages first."
  done
}

install_packages() {
  require_commands rpm
  local package missing_packages=()
  for package in "${FEDORA_PACKAGES[@]}"; do
    rpm -q --whatprovides --quiet "$package" || missing_packages+=("$package")
  done
  if ((${#missing_packages[@]} == 0)); then
    log 'All Fedora packages are installed.'
    return
  fi
  local -a dnf_command=(dnf)
  if ((EUID != 0)); then
    if [[ $DRY_RUN != 1 ]]; then
      sudo -n true || die 'Missing packages require working passwordless sudo. Use a Fedora Distrobox terminal that permits privilege escalation.'
    fi
    dnf_command=(sudo -n dnf)
  fi
  if [[ " ${missing_packages[*]} " == *' starship '* ]]; then
    # A minimal Fedora container may not have the COPR command yet.
    if ! rpm -q --quiet dnf5-plugins; then
      run "${dnf_command[@]}" install -y --setopt=install_weak_deps=False dnf5-plugins
    fi
    run "${dnf_command[@]}" copr enable -y atim/starship
  fi
  run "${dnf_command[@]}" install -y --setopt=install_weak_deps=False "${missing_packages[@]}"
}

# Verify both cached and newly downloaded assets; never cache an incomplete file.
download() {
  local url=$1 dest=$2 checksum=$3 partial
  if [[ -f $dest ]] && printf '%s  %s\n' "$checksum" "$dest" | sha256sum --check --status; then
    return
  fi
  mkdir -p -- "$(dirname -- "$dest")"
  partial=$(mktemp "${dest}.XXXXXX")
  if ! curl --fail --silent --show-error --location --retry 3 --output "$partial" "$url"; then
    rm -f -- "$partial"
    die "Download failed: $url"
  fi
  if ! printf '%s  %s\n' "$checksum" "$partial" | sha256sum --check --status; then
    rm -f -- "$partial"
    die "Checksum mismatch: $url"
  fi
  mv -- "$partial" "$dest"
}

install_fnm() {
  local archive checksum installed='' fnm=$HOME/.local/bin/fnm
  case $(uname -m) in
    x86_64) archive="fnm-linux.zip"; checksum=b69e5c9a05c1e17e4a7de9a17df14ba430d049f2591af791a6f850a170296069 ;;
    aarch64) archive="fnm-arm64.zip"; checksum=69feda9455931c26c84be9f95f5e6f69e8b64686e68069fab7cfc34756cd2944 ;;
    *) die 'fnm supports only x86_64 and aarch64 in this configuration.' ;;
  esac
  if [[ $DRY_RUN == 1 ]]; then
    log "Would install fnm $FNM_VERSION, Node.js $NODE_VERSION and pnpm $PNPM_VERSION."
    return
  fi
  require_commands curl sha256sum unzip
  [[ ! -x $fnm ]] || installed=$("$fnm" --version)
  if [[ $installed != "fnm ${FNM_VERSION#v}" ]]; then
    local zip=$CACHE_ROOT/fnm/$FNM_VERSION/$archive
    download "https://github.com/Schniz/fnm/releases/download/$FNM_VERSION/$archive" "$zip" "$checksum"
    mkdir -p "$HOME/.local/bin"
    unzip -oq "$zip" -d "$HOME/.local/bin"
    chmod 755 "$fnm"
  fi
  "$fnm" install "$NODE_VERSION"
  "$fnm" default "$NODE_VERSION"
  local pnpm_release
  pnpm_release=$("$fnm" exec --using="$NODE_VERSION" pnpm --version 2>/dev/null) || pnpm_release=''
  if [[ $pnpm_release != "$PNPM_VERSION".* ]]; then
    "$fnm" exec --using="$NODE_VERSION" npm install --global "pnpm@$PNPM_VERSION"
  fi
}

install_fonts() {
  local entry archive subdir version checksum url dest marker cached refreshed=0
  local fonts_root=$HOME/.local/share/fonts/dotfiles
  if [[ $DRY_RUN != 1 ]]; then require_commands curl sha256sum tar unzip fc-cache; fi
  for entry in "${FONTS[@]}"; do
    IFS='|' read -r archive subdir version checksum url <<< "$entry"
    dest=$fonts_root/$subdir
    marker=$dest/.dotfiles-installed-$version
    [[ ! -f $marker ]] || continue
    if [[ $DRY_RUN == 1 ]]; then
      log "Would install $subdir $version into $dest."
      continue
    fi
    cached=$CACHE_ROOT/fonts/$FONT_VERSION/$archive
    download "$url" "$cached" "$checksum"
    mkdir -p -- "$dest"
    case $archive in
      *.zip) unzip -oq "$cached" -d "$dest" ;;
      *.tar.xz) tar -xJf "$cached" -C "$dest" ;;
      *) die "Unknown font archive: $archive" ;;
    esac
    # Refresh before marking complete so interrupted installs retry the refresh.
    fc-cache -f "$fonts_root"
    touch "$marker"
    refreshed=1
  done
  if [[ $refreshed == 1 ]]; then log 'Fonts installed and cache refreshed.'; fi
}

backup_conflict() {
  local target=$1 relative=${1#"$HOME/"}
  log "Backing up $target to $BACKUP_ROOT/$relative"
  if [[ -e $BACKUP_ROOT/$relative || -L $BACKUP_ROOT/$relative ]]; then
    die "Backup already exists; refusing to overwrite $BACKUP_ROOT/$relative"
  fi
  run install -d -m 700 -- "$BACKUP_ROOT" "$BACKUP_ROOT/$(dirname -- "$relative")"
  run mv -T -- "$target" "$BACKUP_ROOT/$relative"
}

apply_dotfiles() {
  local package source relative target parent component conflict
  local -a components
  if [[ $DRY_RUN != 1 ]]; then require_commands stow; fi
  for package in "${STOW_PACKAGES[@]}"; do
    [[ -d $ROOT/packages/$package ]] || die "Missing Stow package: $package"
    conflict=0
    while IFS= read -r -d '' source; do
      relative=${source#"$ROOT/packages/$package/"}
      [[ ! $relative =~ $DOTFILES_IGNORE ]] || continue
      target=$HOME/$relative
      # Preserve conflicting parent files and directory symlinks before writing.
      parent=$HOME
      IFS=/ read -r -a components <<< "$relative"
      for component in "${components[@]:0:${#components[@]}-1}"; do
        parent=$parent/$component
        if [[ -L $parent || ( -e $parent && ! -d $parent ) ]]; then
          backup_conflict "$parent"
          conflict=1
          break
        fi
      done
      # In preview mode the conflicting parent still exists; do not follow it.
      if [[ $DRY_RUN == 1 && ( -L $parent || ( -e $parent && ! -d $parent ) ) ]]; then continue; fi
      if [[ -L $target && $target -ef $source ]]; then continue; fi
      if [[ -e $target || -L $target ]]; then
        backup_conflict "$target"
        conflict=1
      fi
    done < <(find "$ROOT/packages/$package" -type f -print0)
    if [[ $DRY_RUN == 1 ]]; then
      if ((conflict)); then
        log "Would stow $package after backing up conflicts."
      elif command -v stow >/dev/null 2>&1; then
        stow --dir "$ROOT/packages" --target "$HOME" --restow --no-folding --verbose=1 \
          --ignore "$DOTFILES_IGNORE" --simulate "$package"
      else
        log "Would stow $package after installing GNU Stow."
      fi
    else
      require_commands stow
      stow --dir "$ROOT/packages" --target "$HOME" --restow --no-folding --verbose=1 \
        --ignore "$DOTFILES_IGNORE" "$package"
    fi
  done
}

check_shell_startup() { bash "${BASH_SOURCE[0]%/*}/check-shell.sh"; }

doctor() {
  local name path source relative target package missing=0 temp node_path
  log "User=$(id -un) HOME=$HOME"
  if command -v fnm >/dev/null 2>&1; then
    # Query the configured runtime without creating an interactive multishell.
    if node_path=$(fnm exec --using="$NODE_VERSION" node -p 'process.execPath'); then
      PATH="$(dirname -- "$node_path"):$PATH"
      export PATH
    else
      printf 'MISS Node.js %s in fnm\n' "$NODE_VERSION"
      missing=1
    fi
  fi
  for name in "${EXPECTED_COMMANDS[@]}"; do
    if path=$(command -v "$name"); then printf 'OK   %-20s %s\n' "$name" "$path"
    else printf 'MISS %s\n' "$name"; missing=1; fi
  done
  for name in "${OPTIONAL_COMMANDS[@]}"; do
    command -v "$name" >/dev/null 2>&1 || printf 'INFO %s manually managed\n' "$name"
  done
  for name in article.cls beamer.cls amsthm.sty mathtools.sty lmodern.sty eepic.sty setspace.sty threeparttable.sty csquotes.sty biblatex.sty; do
    if ! command -v kpsewhich >/dev/null 2>&1 || ! kpsewhich "$name"; then
      printf 'MISS TeX resource %s\n' "$name"; missing=1
    fi
  done
  for package in "${STOW_PACKAGES[@]}"; do
    if [[ ! -d $ROOT/packages/$package ]]; then
      printf 'MISS package %s\n' "$package"; missing=1; continue
    fi
    while IFS= read -r -d '' source; do
      relative=${source#"$ROOT/packages/$package/"}
      [[ ! $relative =~ $DOTFILES_IGNORE ]] || continue
      target=$HOME/$relative
      if [[ ! -L $target || ! $target -ef $source ]]; then
        printf 'MISS link %s\n' "$target"; missing=1
      fi
    done < <(find "$ROOT/packages/$package" -type f -print0)
  done
  if command -v latexmk >/dev/null 2>&1; then
    temp=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-latex.XXXXXX")
    if ! latexmk -pdf -halt-on-error -interaction=nonstopmode "-output-directory=$temp" \
      "$ROOT/packages/nvim-vm/.config/nvim/templates/latex.tex"; then missing=1; fi
    rm -rf -- "$temp"
  fi
  check_shell_startup || missing=1
  ((missing == 0)) || die 'Doctor found missing commands, TeX resources, invalid links, a failed LaTeX build or shell startup errors.'
  log 'Doctor: OK'
}

main() {
  case ${1:-setup} in
    setup) require_fedora; install_packages; install_fnm; install_fonts; apply_dotfiles ;;
    packages) require_fedora; install_packages ;;
    fonts) require_fedora; install_fonts ;;
    fnm) require_fedora; install_fnm ;;
    dotfiles|stow) require_fedora; apply_dotfiles ;;
    doctor) require_fedora; doctor ;;
    *) die "Unknown command: $1" ;;
  esac
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
