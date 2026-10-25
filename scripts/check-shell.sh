#!/usr/bin/env bash
# Exercise the managed startup files without changing the user's shell state.
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export PATH="$HOME/.local/bin:$PATH"
for name in zsh starship script timeout; do
  command -v "$name" >/dev/null || { printf 'Shell check requires %s\n' "$name" >&2; exit 1; }
done
shell_home=$(mktemp -d)
cleanup_shell_check() {
  if [[ ${shell_check_ok:-0} == 1 ]]; then
    rm -rf -- "$shell_home"
  else
    printf 'Shell check diagnostics retained at %s\n' "$shell_home" >&2
  fi
}
trap cleanup_shell_check EXIT
# Preserve the real tool paths while isolating history, completion and caches.
export FNM_DIR=${FNM_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/fnm}
export HOME=$shell_home
export ZDOTDIR=$HOME
export XDG_CACHE_HOME=$HOME/.cache
export XDG_CONFIG_HOME=$HOME/.config
export STARSHIP_CONFIG=$ROOT/packages/starship/.config/starship.toml
export STARSHIP_CACHE=$HOME/.cache/starship
export CONTAINER_ID=fedora
export TERM=xterm-256color
mkdir -p "$HOME/.config"
ln -s "$ROOT/packages/shell-container/.profile" "$HOME/.profile"
ln -s "$ROOT/packages/shell-container/.bashrc" "$HOME/.bashrc"
ln -s "$ROOT/packages/shell-container/.zshrc" "$HOME/.zshrc"
# Keep assertions in a file so terminal line editing cannot change their text.
export DOTFILES_SHELL_PROBE=$shell_home/probe
cat > "$DOTFILES_SHELL_PROBE" <<'PROBE'
printf '\n[diagnostic] zsh=%s starship_shell=%s zdotdir=%s\n' "${ZSH_VERSION:-unset}" "${STARSHIP_SHELL:-unset}" "${ZDOTDIR:-unset}"
command -v starship
if [[ -z ${ZSH_VERSION:-} ]]; then
  printf 'FAIL: interactive Bash did not switch to zsh.\n'; exit 1
fi
if [[ ${STARSHIP_SHELL:-} != zsh || $PROMPT != *starship* ]]; then
  printf 'FAIL: zsh loaded without the Starship prompt. PROMPT=%s\n' "$PROMPT"; exit 1
fi
printf '\nSHELL_STARTUP_OK\n'
exit 0
PROBE
# script otherwise uses the caller's SHELL, which can load an extra startup file.
if ! timeout 30s env SHELL=/bin/sh script -q -e -c 'bash --noprofile -i' "$shell_home/transcript" > "$shell_home/output" 2>&1 <<'INPUT'
source "$DOTFILES_SHELL_PROBE"
INPUT
then
  cat "$shell_home/output" >&2
  printf 'Bash → zsh → Starship startup failed.\n' >&2
  exit 1
fi
if ! grep -q '^SHELL_STARTUP_OK' "$shell_home/transcript"; then
  cat "$shell_home/output" >&2
  printf 'Startup probe did not finish; see the saved transcript.\n' >&2
  exit 1
fi
# Render the actual prompt too; initialization alone does not validate TOML.
starship prompt --status=0 > "$shell_home/prompt" 2> "$shell_home/errors"
if [[ -s $shell_home/errors ]]; then cat "$shell_home/errors" >&2; exit 1; fi
shell_check_ok=1
printf 'Shell startup: Bash → zsh → Starship OK\n'
