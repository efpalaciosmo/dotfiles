#!/usr/bin/env bash
# scripts/vm/languages.sh
# Installs all dev languages/runtimes the dotfiles expect, in user space
# ($HOME only). Designed for the immutable Silverblue host: nothing
# touches /usr.
#
# Idempotent. Each installer:
#   - dynamically resolves the latest stable version from the upstream
#     project's official endpoint (when applicable);
#   - keeps a per-version marker file so re-runs are no-ops;
#   - caches downloaded archives under $HOME/.cache/dotfiles/<lang>/.
#
# Honors DRY_RUN=1.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_LIB="$HOME/.local/lib"
LOCAL_OPT="$HOME/.local/opt"

# ---------- Language selection (toggleable via env) -------------------
# Each installer can be skipped by exporting e.g. SKIP_GO=1.
# ---------------------------------------------------------------------

LANGUAGES=(go fnm julia java uv rust gradle pnpm)

# ---------- Helpers ---------------------------------------------------

arch_go() {
  case "$(uname -m)" in
    x86_64) printf 'amd64\n' ;;
    aarch64|arm64) printf 'arm64\n' ;;
    *) die "Unsupported architecture for Go: $(uname -m)" ;;
  esac
}

arch_adoptium() {
  case "$(uname -m)" in
    x86_64) printf 'x64\n' ;;
    aarch64|arm64) printf 'aarch64\n' ;;
    *) die "Unsupported architecture for JDK: $(uname -m)" ;;
  esac
}

# Write a symlink idempotently. Keeping a stable symlink lets shell config
# point at versionless paths while installers replace versioned directories.
atomic_symlink() {
  local src="$1" dst="$2"
  ensure_dir "$(dirname "$dst")"
  if is_dry_run; then
    printf '[DRY-RUN] ln -sfn %q %q\n' "$src" "$dst"
    return 0
  fi
  ln -sfn "$src" "$dst"
}

# Run a `curl | sh` installer, only printing captured output on failure.
run_installer() {
  local label="$1"; shift
  local out
  out="$(mktemp)"
  if "$@" >"$out" 2>&1; then
    rm -f "$out"
    return 0
  fi
  warn "Installer '$label' failed; combined output:"
  sed -e 's/^/  /' "$out" >&2 || true
  rm -f "$out"
  return 1
}

skip_if_env() {
  local var="SKIP_${1^^}"
  [[ "${!var:-0}" == "1" ]]
}

# ---------- Go --------------------------------------------------------
# https://go.dev/dl/ - latest stable version via https://go.dev/VERSION?m=text

install_go() {
  if skip_if_env go; then summary_skip "go (SKIP_GO=1)"; return 0; fi

  local latest_version target marker tarball url goarch
  if ! latest_version="$(curl -fsSL https://go.dev/VERSION?m=text 2>/dev/null | head -n1)"; then
    summary_fail "go: could not resolve the latest version"
    return 1
  fi
  [[ "$latest_version" =~ ^go ]] || { summary_fail "go: unexpected response from go.dev: $latest_version"; return 1; }

  target="$HOME/.local/go"
  marker="$target/.dotfiles-installed-${latest_version}"

  if [[ -f "$marker" ]] && command -v go >/dev/null 2>&1; then
    log "go is already at latest version: $latest_version"
    summary_skip "go ${latest_version} already installed"
    return 0
  fi

  goarch="$(arch_go)"
  tarball="$CACHE_ROOT/go/${latest_version}.linux-${goarch}.tar.gz"
  url="https://go.dev/dl/${latest_version}.linux-${goarch}.tar.gz"

  ensure_dir "$CACHE_ROOT/go"
  download "$url" "$tarball"

  if is_dry_run; then
    printf '[DRY-RUN] rm -rf %q && tar -C %q -xzf %q && touch %q\n' \
      "$target" "$HOME/.local" "$tarball" "$marker"
    summary_ok "go ${latest_version} (dry-run)"
    return 0
  fi

  rm -rf "$target"
  ensure_dir "$HOME/.local"
  if ! tar -C "$HOME/.local" -xzf "$tarball"; then
    summary_fail "go: extraction failed"
    return 1
  fi
  touch "$marker"
  summary_ok "go ${latest_version} installed at $target"
}

# ---------- fnm (Fast Node Manager) ----------------------------------
# Official installer: https://fnm.vercel.app/install
# --skip-shell prevents upstream from editing .bashrc/.zshrc; dotfiles handle it.

install_fnm() {
  if skip_if_env fnm; then summary_skip "fnm (SKIP_FNM=1)"; return 0; fi

  if [[ -x "$HOME/.local/share/fnm/fnm" ]] && "$HOME/.local/share/fnm/fnm" --version >/dev/null 2>&1; then
    local v
    v="$("$HOME/.local/share/fnm/fnm" --version 2>/dev/null | awk '{print $NF}')"
    log "fnm already installed: $v"
    summary_skip "fnm $v already installed"
    return 0
  fi

  ensure_dir "$HOME/.local/share/fnm"

  if is_dry_run; then
    printf '[DRY-RUN] curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell\n'
    summary_ok "fnm (dry-run)"
    return 0
  fi

  if ! run_installer fnm bash -c 'curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell'; then
    summary_fail "fnm: official installer returned an error"
    return 1
  fi

  if [[ -x "$HOME/.local/share/fnm/fnm" ]]; then
    summary_ok "fnm installed at $HOME/.local/share/fnm"
  else
    summary_fail "fnm: binary was not found after install"
    return 1
  fi
}

# ---------- Julia (via juliaup) --------------------------------------
# https://julialang.org/downloads/  -  https://github.com/JuliaLang/juliaup

install_julia() {
  if skip_if_env julia; then summary_skip "julia (SKIP_JULIA=1)"; return 0; fi

  if command -v julia >/dev/null 2>&1; then
    log "julia already available: $(julia --version 2>/dev/null | head -n1)"
    summary_skip "julia already installed"
    return 0
  fi

  if is_dry_run; then
    printf '[DRY-RUN] curl -fsSL https://install.julialang.org | sh -s -- -y\n'
    summary_ok "julia (dry-run)"
    return 0
  fi

  if ! run_installer juliaup bash -c 'curl -fsSL https://install.julialang.org | sh -s -- --yes --default-channel release'; then
    summary_fail "julia: juliaup failed"
    return 1
  fi

  # juliaup places julia in ~/.juliaup/bin.
  if [[ -x "$HOME/.juliaup/bin/julia" ]]; then
    summary_ok "julia (release) installed via juliaup"
  else
    summary_fail "julia: juliaup finished but the binary is missing"
    return 1
  fi
}

# ---------- Java (Eclipse Temurin / Adoptium JDK 21 LTS) -------------
# API: https://api.adoptium.net/q/swagger-ui/

JDK_FEATURE_VERSION="${JDK_FEATURE_VERSION:-21}"

jdk_latest_release_name() {
  local arch
  arch="$(arch_adoptium)"
  curl -fsSL \
    "https://api.adoptium.net/v3/info/release_versions?architecture=${arch}&heap_size=normal&image_type=jdk&jvm_impl=hotspot&lts=true&os=linux&page=0&page_size=1&project=jdk&release_type=ga&sort_method=DEFAULT&sort_order=DESC&vendor=eclipse&version=%5B${JDK_FEATURE_VERSION}%2C${JDK_FEATURE_VERSION}.999.999%5D" \
    2>/dev/null \
    | { has_cmd jq && jq -r '.versions[0].openjdk_version' 2>/dev/null \
        || python3 -c 'import json,sys;d=json.load(sys.stdin);print(d["versions"][0]["openjdk_version"])' 2>/dev/null; }
}

install_java() {
  if skip_if_env java; then summary_skip "java (SKIP_JAVA=1)"; return 0; fi

  local release tag versioned_dir marker tarball url arch
  release="$(jdk_latest_release_name || true)"
  if [[ -z "$release" ]]; then
    summary_fail "java: could not resolve latest JDK ${JDK_FEATURE_VERSION} release (Adoptium)"
    return 1
  fi

  # 'release' comes back as '21.0.5+11'; use it as the version tag.
  tag="$release"
  versioned_dir="$LOCAL_LIB/jdk-${tag}"
  marker="$versioned_dir/.dotfiles-installed"
  arch="$(arch_adoptium)"

  if [[ -f "$marker" ]] && [[ -x "$versioned_dir/bin/java" ]]; then
    log "JDK ${tag} already installed at $versioned_dir"
    atomic_symlink "$versioned_dir" "$LOCAL_LIB/jdk"
    summary_skip "java ${tag} already installed (symlink jdk -> ${versioned_dir##*/})"
    return 0
  fi

  tarball="$CACHE_ROOT/java/temurin-${tag}-linux-${arch}.tar.gz"
  ensure_dir "$CACHE_ROOT/java"

  url="https://api.adoptium.net/v3/binary/version/jdk-${tag}/linux/${arch}/jdk/hotspot/normal/eclipse?project=jdk"
  log "Downloading JDK ${tag} (Eclipse Temurin) -> $tarball"
  if ! curl -fsSL --retry 3 -o "$tarball" "$url"; then
    summary_fail "java: download failed ($url)"
    return 1
  fi

  if is_dry_run; then
    printf '[DRY-RUN] extract %q -> %q + symlink\n' "$tarball" "$versioned_dir"
    summary_ok "java ${tag} (dry-run)"
    return 0
  fi

  local tmp extracted
  tmp="$(mktemp -d)"
  if ! tar -C "$tmp" -xzf "$tarball"; then
    rm -rf "$tmp"
    summary_fail "java: extraction failed"
    return 1
  fi
  extracted="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n1)"

  ensure_dir "$LOCAL_LIB"
  rm -rf "$versioned_dir"
  mv "$extracted" "$versioned_dir"
  rm -rf "$tmp"
  touch "$marker"

  atomic_symlink "$versioned_dir" "$LOCAL_LIB/jdk"
  summary_ok "java ${tag} installed (symlink: $LOCAL_LIB/jdk -> ${versioned_dir##*/})"
}

# ---------- uv (Astral) ----------------------------------------------

install_uv() {
  if skip_if_env uv; then summary_skip "uv (SKIP_UV=1)"; return 0; fi

  if command -v uv >/dev/null 2>&1; then
    log "uv already installed: $(uv --version 2>/dev/null)"
    summary_skip "uv already installed"
    return 0
  fi

  if is_dry_run; then
    printf '[DRY-RUN] curl -LsSf https://astral.sh/uv/install.sh | sh\n'
    summary_ok "uv (dry-run)"
    return 0
  fi

  ensure_dir "$LOCAL_BIN"
  if ! run_installer uv bash -c 'curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$HOME/.local/bin" sh -s -- --quiet'; then
    summary_fail "uv: installer returned an error"
    return 1
  fi

  if command -v uv >/dev/null 2>&1 || [[ -x "$LOCAL_BIN/uv" ]]; then
    summary_ok "uv installed"
  else
    summary_fail "uv: binary is missing after install"
    return 1
  fi
}

# ---------- Rust (rustup) --------------------------------------------

install_rust() {
  if skip_if_env rust; then summary_skip "rust (SKIP_RUST=1)"; return 0; fi

  if command -v rustc >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
    log "rust already installed: $(rustc --version 2>/dev/null)"
    summary_skip "rust already installed"
    return 0
  fi

  if is_dry_run; then
    printf '[DRY-RUN] curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable\n'
    summary_ok "rust (dry-run)"
    return 0
  fi

  if ! run_installer rustup bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable"; then
    summary_fail "rust: rustup failed"
    return 1
  fi

  if [[ -x "$HOME/.cargo/bin/rustc" ]]; then
    summary_ok "rust installed via rustup"
  else
    summary_fail "rust: rustup finished but rustc is missing"
    return 1
  fi
}

# ---------- Gradle ---------------------------------------------------
# https://services.gradle.org/versions/current  -> {"version":"8.X.Y", ...}

gradle_latest_version() {
  curl -fsSL https://services.gradle.org/versions/current 2>/dev/null \
    | { has_cmd jq && jq -r '.version' 2>/dev/null \
        || python3 -c 'import json,sys;print(json.load(sys.stdin)["version"])' 2>/dev/null; }
}

install_gradle() {
  if skip_if_env gradle; then summary_skip "gradle (SKIP_GRADLE=1)"; return 0; fi

  local version versioned_dir marker zip url
  version="$(gradle_latest_version || true)"
  if [[ -z "$version" ]]; then
    summary_fail "gradle: could not resolve latest version"
    return 1
  fi

  versioned_dir="$LOCAL_OPT/gradle-${version}"
  marker="$versioned_dir/.dotfiles-installed"

  if [[ -f "$marker" ]] && [[ -x "$versioned_dir/bin/gradle" ]]; then
    log "gradle ${version} already installed at $versioned_dir"
    atomic_symlink "$versioned_dir" "$LOCAL_OPT/gradle"
    summary_skip "gradle ${version} already installed"
    return 0
  fi

  if ! has_cmd unzip; then
    summary_fail "gradle: 'unzip' is not available (it should come from dnf)"
    return 1
  fi

  ensure_dir "$CACHE_ROOT/gradle"
  zip="$CACHE_ROOT/gradle/gradle-${version}-bin.zip"
  url="https://services.gradle.org/distributions/gradle-${version}-bin.zip"
  download "$url" "$zip"

  if is_dry_run; then
    printf '[DRY-RUN] extract %q -> %q + symlink\n' "$zip" "$versioned_dir"
    summary_ok "gradle ${version} (dry-run)"
    return 0
  fi

  local tmp
  tmp="$(mktemp -d)"
  if ! unzip -q "$zip" -d "$tmp"; then
    rm -rf "$tmp"
    summary_fail "gradle: extraction failed"
    return 1
  fi

  ensure_dir "$LOCAL_OPT"
  rm -rf "$versioned_dir"
  mv "$tmp/gradle-${version}" "$versioned_dir"
  rm -rf "$tmp"
  touch "$marker"

  atomic_symlink "$versioned_dir" "$LOCAL_OPT/gradle"
  summary_ok "gradle ${version} installed (symlink: $LOCAL_OPT/gradle -> gradle-${version})"
}

# ---------- pnpm ------------------------------------------------------
# Official standalone installer: https://pnpm.io/installation

install_pnpm() {
  if skip_if_env pnpm; then summary_skip "pnpm (SKIP_PNPM=1)"; return 0; fi

  if command -v pnpm >/dev/null 2>&1; then
    log "pnpm already installed: $(pnpm --version 2>/dev/null)"
    summary_skip "pnpm already installed"
    return 0
  fi

  if is_dry_run; then
    printf '[DRY-RUN] curl -fsSL https://get.pnpm.io/install.sh | sh -s -- ENV="$HOME/.profile" SHELL=$(command -v sh)\n'
    summary_ok "pnpm (dry-run)"
    return 0
  fi

  # PNPM_HOME matches the path expected by the dotfiles config.
  if ! run_installer pnpm bash -c '
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export SHELL="$(command -v sh)"
    curl -fsSL https://get.pnpm.io/install.sh | sh -s -- -y
  '; then
    summary_fail "pnpm: installer returned an error"
    return 1
  fi

  if [[ -x "$HOME/.local/share/pnpm/pnpm" ]]; then
    summary_ok "pnpm installed at $HOME/.local/share/pnpm"
  else
    summary_fail "pnpm: binary is missing after install"
    return 1
  fi
}

# ---------- Orchestrator ----------------------------------------------

run_one() {
  local lang="$1"
  printf '\n%s>> Installing %s%s\n' "$_DOTFILES_CLR_INFO" "$lang" "$_DOTFILES_CLR_RESET"
  if ! "install_${lang}"; then
    warn "${lang} installer failed (continuing with the rest)"
  fi
}

main() {
  log "=== languages.sh === (DRY_RUN=${DRY_RUN:-0})"
  ensure_dir "$LOCAL_BIN"
  ensure_dir "$LOCAL_LIB"
  ensure_dir "$LOCAL_OPT"
  ensure_dir "$CACHE_ROOT"

  local lang
  for lang in "${LANGUAGES[@]}"; do
    run_one "$lang"
  done

  if print_summary "Languages (vm)"; then
    return 0
  fi
  return 1
}

main "$@"
