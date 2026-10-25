#!/usr/bin/env bash
# Offline regression tests: isolated HOME, real Stow, mocked package installation.
set -Eeuo pipefail
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT
export HOME=$TEST_ROOT/home
export XDG_CACHE_HOME=$TEST_ROOT/cache
mkdir -p "$HOME"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../scripts/setup.sh
source "$REPO/scripts/setup.sh"
require_commands stow curl sha256sum
ROOT=$TEST_ROOT/repo
STOW_PACKAGES=(sample)
mkdir -p "$ROOT/packages/sample/.config/tool" "$HOME/.config/tool"
printf 'managed\n' > "$ROOT/packages/sample/.config/tool/settings"
printf 'keep\n' > "$HOME/.config/tool/settings"
printf 'ignored\n' > "$ROOT/packages/sample/.config/tool/auth.json"
printf 'lock\n' > "$ROOT/packages/sample/.config/tool/package-lock.json"

# A preview must preserve conflicting files and avoid creating backups or links.
DRY_RUN=1
apply_dotfiles
[[ $(cat "$HOME/.config/tool/settings") == keep ]]
[[ ! -e $BACKUP_ROOT && ! -e $HOME/.config/tool/auth.json ]]
DRY_RUN=0
apply_dotfiles
[[ -L $HOME/.config/tool/settings && $HOME/.config/tool/settings -ef $ROOT/packages/sample/.config/tool/settings ]]
[[ $(cat "$BACKUP_ROOT/.config/tool/settings") == keep ]]
[[ $(stat -c %a "$BACKUP_ROOT") == 700 ]]
[[ ! -e $HOME/.config/tool/auth.json && ! -e $HOME/.config/tool/package-lock.json ]]
# Repeat without replacing the link or creating another backup.
before=$(readlink "$HOME/.config/tool/settings")
BACKUP_ROOT=$TEST_ROOT/second-backup
apply_dotfiles
[[ $(readlink "$HOME/.config/tool/settings") == "$before" && ! -e $BACKUP_ROOT ]]

# Broken links, parent files and parent symlinks must be preserved before Stow.
rm "$HOME/.config/tool/settings"
ln -s /nonexistent-dotfiles-test "$HOME/.config/tool/settings"
apply_dotfiles
[[ -L $BACKUP_ROOT/.config/tool/settings ]]
[[ $HOME/.config/tool/settings -ef $ROOT/packages/sample/.config/tool/settings ]]
rm "$HOME/.config/tool/settings"
rmdir "$HOME/.config/tool"
printf 'parent\n' > "$HOME/.config/tool"
BACKUP_ROOT=$TEST_ROOT/parent-backup
apply_dotfiles
[[ $(cat "$BACKUP_ROOT/.config/tool") == parent ]]
[[ $HOME/.config/tool/settings -ef $ROOT/packages/sample/.config/tool/settings ]]
rm "$HOME/.config/tool/settings"
rmdir "$HOME/.config/tool"
mkdir "$TEST_ROOT/external"
printf 'external\n' > "$TEST_ROOT/external/settings"
ln -s "$TEST_ROOT/external" "$HOME/.config/tool"
BACKUP_ROOT=$TEST_ROOT/symlink-backup
apply_dotfiles
[[ -L $BACKUP_ROOT/.config/tool && ! -L $HOME/.config/tool ]]
[[ $(cat "$TEST_ROOT/external/settings") == external ]]

# A conflicting directory is moved intact, preserving its unrelated files.
rm "$HOME/.config/tool/settings"
mkdir "$HOME/.config/tool/settings"
printf 'nested\n' > "$HOME/.config/tool/settings/unrelated"
BACKUP_ROOT=$TEST_ROOT/directory-backup
apply_dotfiles
[[ $(cat "$BACKUP_ROOT/.config/tool/settings/unrelated") == nested ]]
[[ $HOME/.config/tool/settings -ef $ROOT/packages/sample/.config/tool/settings ]]
# Existing backups cannot be silently overwritten on another conflict.
rm "$HOME/.config/tool/settings"
printf 'new conflict\n' > "$HOME/.config/tool/settings"
if (apply_dotfiles); then printf 'FAIL: existing backup overwritten\n' >&2; exit 1; fi
[[ $(cat "$HOME/.config/tool/settings") == 'new conflict' ]]
[[ $(cat "$BACKUP_ROOT/.config/tool/settings/unrelated") == nested ]]
BACKUP_ROOT=$TEST_ROOT/after-collision
apply_dotfiles

# Downloads are checksum checked, reused when valid, and repaired when corrupted.
printf 'asset\n' > "$TEST_ROOT/asset"
checksum=$(sha256sum "$TEST_ROOT/asset"); checksum=${checksum%% *}
download "file://$TEST_ROOT/asset" "$TEST_ROOT/download/asset" "$checksum"
printf 'corrupt\n' > "$TEST_ROOT/download/asset"
download "file://$TEST_ROOT/asset" "$TEST_ROOT/download/asset" "$checksum"
cmp "$TEST_ROOT/asset" "$TEST_ROOT/download/asset"
# A cached asset needs no download, even when the source is no longer available.
download 'file:///does-not-exist' "$TEST_ROOT/download/asset" "$checksum"
if (download "file://$TEST_ROOT/asset" "$TEST_ROOT/download/bad" "${checksum//?/0}"); then
  printf 'FAIL: accepted an invalid checksum\n' >&2; exit 1
fi
[[ ! -e $TEST_ROOT/download/bad ]]

# Only missing RPM packages are passed to DNF; dry-run must never invoke it.
FEDORA_PACKAGES=(present missing)
rpm() { [[ ${*: -1} == present ]]; }
mkdir -p "$TEST_ROOT/bin"
export TEST_ROOT
export PATH="$TEST_ROOT/bin:$PATH"
cat > "$TEST_ROOT/bin/dnf" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_ROOT/dnf-call"
STUB
cat > "$TEST_ROOT/bin/sudo" <<'STUB'
#!/usr/bin/env bash
[[ $1 != -n ]] || shift
"$@"
STUB
chmod +x "$TEST_ROOT/bin/dnf" "$TEST_ROOT/bin/sudo"
DRY_RUN=1
install_packages
[[ ! -e $TEST_ROOT/dnf-call ]]
DRY_RUN=0
install_packages
[[ $(cat "$TEST_ROOT/dnf-call") == 'install -y --setopt=install_weak_deps=False missing' ]]
# Starship must enable the documented RPM repository before its DNF install.
rm "$TEST_ROOT/dnf-call"
FEDORA_PACKAGES=(starship)
install_packages
[[ $(sed -n '1p' "$TEST_ROOT/dnf-call") == 'install -y --setopt=install_weak_deps=False dnf5-plugins' ]]
[[ $(sed -n '2p' "$TEST_ROOT/dnf-call") == 'copr enable -y atim/starship' ]]
[[ $(sed -n '3p' "$TEST_ROOT/dnf-call") == 'install -y --setopt=install_weak_deps=False starship' ]]
unset -f rpm
rm "$TEST_ROOT/bin/dnf" "$TEST_ROOT/bin/sudo"

# Fonts are installed once, including their font-cache refresh.
mkdir "$TEST_ROOT/font-source"
printf 'font\n' > "$TEST_ROOT/font-source/test.ttf"
tar -cJf "$TEST_ROOT/font.tar.xz" -C "$TEST_ROOT/font-source" test.ttf
checksum=$(sha256sum "$TEST_ROOT/font.tar.xz"); checksum=${checksum%% *}
FONTS=("font.tar.xz|Test|v1|$checksum|file://$TEST_ROOT/font.tar.xz")
fc-cache() { printf 'refresh\n' >> "$TEST_ROOT/font-refresh"; }
install_fonts
install_fonts
[[ $(cat "$TEST_ROOT/font-refresh") == refresh ]]
[[ -f $HOME/.local/share/fonts/dotfiles/Test/test.ttf ]]
unset -f fc-cache

# Repeatedly sourcing the shared environment must not grow PATH.
profile_path=$PATH
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../packages/shell-container/.profile
source "$REPO/packages/shell-container/.profile"
after_profile=$PATH
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../packages/shell-container/.profile
source "$REPO/packages/shell-container/.profile"
[[ $PATH == "$after_profile" ]]
PATH=$profile_path
export PATH

# An existing pinned fnm is reused and pnpm installs only when its major differs.
mkdir -p "$HOME/.local/bin"
export TEST_ROOT
cat > "$HOME/.local/bin/fnm" <<'STUB'
#!/usr/bin/env bash
set -eu
case $1 in
  --version) printf 'fnm 1.38.1\n' ;;
  install|default) printf '%s\n' "$*" >> "$TEST_ROOT/node-calls" ;;
  exec)
    shift 2
    case $1 in
      pnpm) [[ -f $TEST_ROOT/pnpm-installed ]] && printf '10.1.0\n' ;;
      npm) printf '%s\n' "$*" >> "$TEST_ROOT/npm-calls"; touch "$TEST_ROOT/pnpm-installed" ;;
      *) exit 1 ;;
    esac ;;
  *) exit 1 ;;
esac
STUB
chmod +x "$HOME/.local/bin/fnm"
install_fnm
install_fnm
[[ $(cat "$TEST_ROOT/npm-calls") == 'npm install --global pnpm@10' ]]
[[ $(wc -l < "$TEST_ROOT/node-calls") == 4 ]]
rm "$HOME/.local/bin/fnm"

# Doctor checks that links resolve to this repository, not just any valid file.
EXPECTED_COMMANDS=(bash)
OPTIONAL_COMMANDS=()
check_shell_startup() { :; }
kpsewhich() { :; }
latexmk() { :; }
fnm() { [[ $1 == exec ]] && command -v bash; }
doctor
rm "$HOME/.config/tool/settings"
ln -s "$TEST_ROOT/external/settings" "$HOME/.config/tool/settings"
if (doctor); then printf 'FAIL: doctor accepted an unrelated symlink\n' >&2; exit 1; fi
unset -f check_shell_startup kpsewhich latexmk fnm
printf 'Bash regression tests: OK\n'
