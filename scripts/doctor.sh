#!/usr/bin/env bash
# scripts/doctor.sh
# Environment health check. Detects context (host vs distrobox), reports
# critical commands, PATH, GOPATH, podman bridge state, etc.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

context() {
  log "Context:"
  if is_distrobox; then
    log "  - Distrobox: YES (probably inside the container)"
    if [[ -r /etc/os-release ]]; then
      # shellcheck disable=SC1091
      ( . /etc/os-release && log "  - Distro: ${PRETTY_NAME:-${ID:-?}} ${VERSION_ID:-}" )
    fi
  else
    log "  - Distrobox: NO (host)"
  fi

  if is_ostree_host; then
    log "  - ostree-booted: YES (Fedora Silverblue / Atomic)"
  else
    log "  - ostree-booted: NO"
  fi

  log "  - USER=$USER, HOME=$HOME"
}

check_commands() {
  local critical=(bash tar python3)
  local optional=(curl wget git make stown shellcheck)
  local host_only=(flatpak podman)
  local vm_only=(dnf code-insiders podman-compose)

  log "Critical commands:"
  for c in "${critical[@]}"; do
    if has_cmd "$c"; then
      log "  - $c: $(command -v "$c")"
    else
      warn "  - $c: MISSING"
    fi
  done

  log "Optional/useful commands:"
  for c in "${optional[@]}"; do
    if has_cmd "$c"; then
      log "  - $c: $(command -v "$c")"
    else
      log "  - $c: (not installed)"
    fi
  done

  if is_distrobox; then
    log "Expected VM commands:"
    for c in "${vm_only[@]}"; do
      if has_cmd "$c"; then
        log "  - $c: $(command -v "$c")"
      else
        warn "  - $c: MISSING (run 'make vm')"
      fi
    done
  else
    log "Expected host commands:"
    for c in "${host_only[@]}"; do
      if has_cmd "$c"; then
        log "  - $c: $(command -v "$c")"
      else
        warn "  - $c: MISSING (check Silverblue base)"
      fi
    done
    if has_cmd distrobox; then
      log "  - distrobox: $(command -v distrobox)"
    else
      warn "  - distrobox: MISSING (run 'make distrobox')"
    fi
  fi
}

check_path() {
  log "PATH (one entry per line):"
  local IFS=':'
  for p in $PATH; do
    log "  - $p"
  done

  if [[ ":${PATH:-}:" == *":$HOME/.local/bin:"* ]]; then
    log "  ✓ \$HOME/.local/bin is in PATH"
  else
    warn "  ✗ \$HOME/.local/bin is NOT in PATH (check ~/.profile)"
  fi
}

check_go_env() {
  if [[ -z "${GOPATH:-}" ]]; then
    log "GOPATH is not set (you have not opened a shell with the new config yet)"
    return 0
  fi
  log "GOPATH=$GOPATH"
  if [[ "$GOPATH" == "$HOME/.go" ]]; then
    log "  ✓ GOPATH points to \$HOME/.go (correct)"
  else
    warn "  ✗ GOPATH does NOT point to \$HOME/.go (expected by the new config)"
  fi
}

check_podman_bridge() {
  if ! is_distrobox; then
    return 0
  fi

  if ! has_cmd podman; then
    warn "podman is not in PATH inside the container"
    return 0
  fi

  local p target
  p="$(command -v podman)"
  target="$(readlink -f "$p" || true)"
  log "podman -> $p (resolved: $target)"
  if [[ "$target" == *"distrobox-host-exec"* ]]; then
    log "  ✓ podman inside the container uses distrobox-host-exec"
  else
    warn "  ✗ podman inside the container does NOT point to distrobox-host-exec"
    warn "    Fix with: sudo ln -sfn /usr/bin/distrobox-host-exec /usr/local/bin/podman"
  fi
}

check_default_editor() {
  if ! is_distrobox; then
    return 0
  fi
  if has_cmd xdg-mime; then
    log "xdg-mime query default text/plain: $(xdg-mime query default text/plain 2>/dev/null || echo '?')"
  fi
}

check_languages() {
  if ! is_distrobox; then
    return 0
  fi

  log "Languages / runtimes:"

  # name:version-flag pairs. Each entry is <command>:<version flag>.
  local -a langs=(
    "go:version"
    "zig:version"
    "node:--version"
    "fnm:--version"
    "julia:--version"
    "java:-version"
    "javac:-version"
    "uv:--version"
    "gradle:--version"
    "pnpm:--version"
    "starship:--version"
  )

  local entry cmd flag ver
  for entry in "${langs[@]}"; do
    cmd="${entry%%:*}"
    flag="${entry##*:}"
    if has_cmd "$cmd"; then
      # `java -version` and `gradle --version` write to stderr; combine both.
      ver="$("$cmd" $flag 2>&1 | head -n1)"
      log "  ✓ $cmd: ${ver:-present} ($(command -v "$cmd"))"
    else
      warn "  ✗ $cmd: missing"
    fi
  done

  log "Expected versionless symlinks/directories:"
  for entry in "$HOME/.local/lib/jdk:JAVA_HOME" "$HOME/.local/opt/gradle:GRADLE_HOME" "$HOME/.local/go:GOROOT"; do
    cmd="${entry%%:*}"
    flag="${entry##*:}"
    if [[ -L "$cmd" ]]; then
      log "  ✓ $cmd ($flag) -> $(readlink "$cmd")"
    elif [[ -d "$cmd" ]]; then
      log "  ✓ $cmd ($flag) (real directory)"
    else
      warn "  ✗ $cmd ($flag) missing"
    fi
  done
}

check_dotfiles_links() {
  local profile=""
  if is_distrobox; then
    profile="vm"
  else
    profile="home"
  fi

  if [[ ! -d "$REPO_ROOT/$profile" ]]; then
    warn "$REPO_ROOT/$profile does not exist (cannot check symlinks)"
    return 0
  fi

  log "Dotfile symlinks ($profile):"
  local src target rel link link_canon src_canon
  src_canon=""
  while IFS= read -r -d '' src; do
    rel="${src#"$REPO_ROOT/$profile/"}"
    rel="${rel#*/}"  # strip <package>/ prefix
    target="$HOME/$rel"
    if [[ -L "$target" ]]; then
      link="$(readlink "$target")"
      # stown writes RELATIVE symlinks; canonicalize both sides so the
      # comparison works regardless of the literal target string.
      link_canon="$(readlink -f "$target" 2>/dev/null || true)"
      src_canon="$(readlink -f "$src" 2>/dev/null || echo "$src")"
      if [[ -n "$link_canon" && "$link_canon" == "$src_canon" ]]; then
        log "  ✓ $target -> $link"
      else
        warn "  ! $target -> $link (does not point to the repo)"
      fi
    elif [[ -e "$target" ]]; then
      warn "  ! $target exists but is NOT a symlink"
    else
      warn "  - $target missing (run 'make stown-$profile')"
    fi
  done < <(find "$REPO_ROOT/$profile" -mindepth 2 -type f -print0)
}

main() {
  log "=== make doctor ==="
  context
  printf '\n'
  check_commands
  printf '\n'
  check_path
  printf '\n'
  check_go_env
  printf '\n'
  check_podman_bridge
  printf '\n'
  check_default_editor
  printf '\n'
  check_languages
  printf '\n'
  check_dotfiles_links
}

main "$@"
