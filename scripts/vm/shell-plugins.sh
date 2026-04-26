#!/usr/bin/env bash
# scripts/vm/shell-plugins.sh
# Install oh-my-zsh + zsh-autosuggestions + zsh-syntax-highlighting in
# user space. Idempotent: if a directory exists we update it via
# `git pull` instead of cloning again.
#
# The dotfiles `vm/shell/.zshrc` only loads these plugins when their
# directories exist, so this script just makes them appear.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

ensure_zsh_binary() {
  if ! has_cmd zsh; then
    summary_fail "zsh is not installed (packages-fedora.sh installs it)"
    return 1
  fi
}

install_oh_my_zsh() {
  if [[ -d "$ZSH_DIR" ]]; then
    log "oh-my-zsh already present at $ZSH_DIR"
    summary_skip "oh-my-zsh already installed"
    return 0
  fi

  if is_dry_run; then
    printf '[DRY-RUN] curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended --keep-zshrc\n'
    summary_ok "oh-my-zsh (dry-run)"
    return 0
  fi

  local out
  out="$(mktemp)"
  # --keep-zshrc prevents the installer from overwriting the stown-managed
  # .zshrc. CHSH=no and RUNZSH=no keep it from changing the shell or launching zsh.
  if ! env CHSH=no RUNZSH=no KEEP_ZSHRC=yes \
       sh -c 'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended --keep-zshrc' \
       >"$out" 2>&1; then
    warn "oh-my-zsh: installer failed:"
    sed -e 's/^/  /' "$out" >&2 || true
    rm -f "$out"
    summary_fail "oh-my-zsh: installer returned an error"
    return 1
  fi
  rm -f "$out"

  if [[ -d "$ZSH_DIR" ]]; then
    summary_ok "oh-my-zsh installed at $ZSH_DIR"
  else
    summary_fail "oh-my-zsh: directory is missing after install"
    return 1
  fi
}

# clone_or_update <git-url> <destination>
clone_or_update() {
  local url="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    log "Updating $(basename "$dest") at $dest"
    if is_dry_run; then
      printf '[DRY-RUN] git -C %q pull --ff-only\n' "$dest"
      return 0
    fi
    git -C "$dest" pull --ff-only --quiet || warn "git pull failed in $dest (continuing)"
  else
    log "Cloning $(basename "$dest") into $dest"
    ensure_dir "$(dirname "$dest")"
    if is_dry_run; then
      printf '[DRY-RUN] git clone --depth 1 %q %q\n' "$url" "$dest"
      return 0
    fi
    git clone --depth 1 --quiet "$url" "$dest"
  fi
}

install_zsh_plugins() {
  if ! has_cmd git; then
    summary_fail "git is not available (packages-fedora.sh installs it)"
    return 1
  fi

  ensure_dir "$ZSH_CUSTOM/plugins"

  if clone_or_update https://github.com/zsh-users/zsh-autosuggestions \
       "$ZSH_CUSTOM/plugins/zsh-autosuggestions"; then
    summary_ok "zsh-autosuggestions"
  else
    summary_fail "zsh-autosuggestions: clone/update failed"
  fi

  if clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting \
       "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"; then
    summary_ok "zsh-syntax-highlighting"
  else
    summary_fail "zsh-syntax-highlighting: clone/update failed"
  fi
}

main() {
  log "=== shell-plugins.sh === (DRY_RUN=${DRY_RUN:-0})"
  ensure_zsh_binary
  install_oh_my_zsh
  install_zsh_plugins

  if print_summary "Shell plugins (vm)"; then
    return 0
  fi
  return 1
}

main "$@"
