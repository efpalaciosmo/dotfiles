#!/usr/bin/env bash
# scripts/stown/apply.sh
# Apply dotfiles for a profile (`home` or `vm`) using `stown` (Python).
#
# stown CLI:    stown TARGET SOURCE [SOURCE...]
# stown package layout used here:
#   <profile>/<package>/<relative-path-inside-$HOME>
# e.g. home/shell/.zshrc        -> $HOME/.zshrc
#      vm/nvim/.config/nvim/... -> $HOME/.config/nvim/...
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

PROFILE="${1:-}"
case "$PROFILE" in
  home|vm) ;;
  *) die "Uso: $0 <home|vm>" ;;
esac

PROFILE_ROOT="$REPO_ROOT/$PROFILE"

if [[ ! -d "$PROFILE_ROOT" ]]; then
  die "Profile directory does not exist: $PROFILE_ROOT"
fi

# Patterns to ignore when scanning packages.
IGNORE_REGEX='(^|/)(\.git|\.gitkeep|\.DS_Store|README\.md|README|.*\.md\.template)$'

# List packages under the profile (top-level directories only).
list_packages() {
  find "$PROFILE_ROOT" -mindepth 1 -maxdepth 1 -type d \
    | sort
}

# Given a source file inside the package, compute its target under $HOME.
# pkg_dir = absolute path to package, src = absolute path to file inside pkg
target_for() {
  local pkg_dir="$1" src="$2"
  local rel="${src#$pkg_dir/}"
  printf '%s/%s\n' "$HOME" "$rel"
}

# Pre-flight: walk leaves and back up conflicts.
backup_conflicts() {
  local pkg_dir="$1"
  local src target target_link

  while IFS= read -r -d '' src; do
    target="$(target_for "$pkg_dir" "$src")"

    if [[ -L "$target" ]]; then
      target_link="$(readlink "$target")"
      if [[ "$target_link" == "$src" ]]; then
        continue
      fi
      log "Existing symlink points to another target: $target -> $target_link"
      backup_path "$target"
    elif [[ -e "$target" ]]; then
      log "Archivo real bloqueando destino: $target"
      backup_path "$target"
    fi
  done < <(find "$pkg_dir" -regextype posix-extended -type f -not -regex ".*$IGNORE_REGEX" -print0)
}

apply_package() {
  local pkg_dir="$1"
  local pkg_name
  pkg_name="$(basename "$pkg_dir")"

  log "Paquete: $PROFILE/$pkg_name"

  backup_conflicts "$pkg_dir"

  local args=(--force)
  if is_dry_run; then
    args+=(--dry-run)
  fi
  if run_or_print stown "${args[@]}" "$HOME" "$pkg_dir"; then
    summary_ok "stown $PROFILE/$pkg_name"
  else
    summary_fail "stown $PROFILE/$pkg_name (check output)"
  fi
}

main() {
  log "Applying '$PROFILE' profile dotfiles from $PROFILE_ROOT"
  log "Backups (si los hay) en: \$HOME/.dotfiles-backup/$DOTFILES_BACKUP_STAMP"

  has_cmd stown || die "stown is not available. Install it with: scripts/home/python-user-tools.sh"
  log "Usando stown $(stown --version 2>/dev/null | head -n1 || echo "?")"

  local pkg
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    apply_package "$pkg"
  done < <(list_packages)

  print_summary "stown apply ($PROFILE)" || true
}

main "$@"
