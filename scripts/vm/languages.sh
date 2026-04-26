#!/usr/bin/env bash
# scripts/vm/languages.sh
# Installs all dev languages/runtimes the dotfiles expect, in user space
# ($HOME only). Designed for the immutable Silverblue host: nothing
# touches /usr.
#
# Idempotent. Each installer:
#   - dynamically resolves the latest stable version from the upstream
#     project's official endpoint (when applicable);
#   - keeps a per-version marker file or upstream marker so re-runs
#     are no-ops;
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

LANGUAGES=(go fnm julia java uv gradle pnpm)

# ---------- Helpers ---------------------------------------------------

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

# ---------- Progress bar ---------------------------------------------
# Renders a simple ASCII progress bar on stderr. Width is 30 cells.
# Usage: progress_bar <step> <total> <label>
progress_bar() {
  local step="$1" total="$2" label="$3"
  local width=30
  local filled=$(( step * width / total ))
  local pct=$(( step * 100 / total ))
  local bar="" i
  for (( i = 0; i < filled; i++ )); do bar+="#"; done
  for (( i = filled; i < width; i++ )); do bar+="-"; done
  printf '%s[%d/%d] [%s] %3d%% %s%s\n' \
    "$_DOTFILES_CLR_INFO" "$step" "$total" "$bar" "$pct" "$label" "$_DOTFILES_CLR_RESET"
}

# ---------- Go (via gvm) ---------------------------------------------
# https://github.com/moovweb/gvm
# gvm needs: bison, gcc, make, glibc-devel (provided by packages-fedora.sh).
# Layout: ~/.gvm/scripts/gvm + ~/.gvm/gos/<version>.

GVM_DIR="$HOME/.gvm"

ensure_gvm() {
  if [[ -s "$GVM_DIR/scripts/gvm" ]]; then
    return 0
  fi

  if is_dry_run; then
    printf '[DRY-RUN] curl -fsSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash\n'
    return 0
  fi

  if ! has_cmd bison; then
    warn "bison is missing; gvm needs it to build Go from source. Install it with packages-fedora.sh."
  fi

  if ! run_installer gvm bash -c 'curl -fsSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash'; then
    return 1
  fi
}

gvm_latest_go() {
  curl -fsSL https://go.dev/VERSION?m=text 2>/dev/null | head -n1 | sed 's/^go//'
}

install_go() {
  if skip_if_env go; then summary_skip "go (SKIP_GO=1)"; return 0; fi

  local latest binary_pkg
  latest="$(gvm_latest_go || true)"
  if [[ -z "$latest" ]]; then
    summary_fail "go: could not resolve the latest Go version"
    return 1
  fi
  binary_pkg="go${latest}"

  if ! ensure_gvm; then
    summary_fail "go: could not install gvm"
    return 1
  fi

  if is_dry_run; then
    printf '[DRY-RUN] gvm install %s -B && gvm use %s --default\n' "$binary_pkg" "$binary_pkg"
    summary_ok "go ${binary_pkg} via gvm (dry-run)"
    return 0
  fi

  # Versioned marker so re-runs are cheap.
  local marker="$GVM_DIR/.dotfiles-installed-${binary_pkg}"
  if [[ -f "$marker" ]] && [[ -d "$GVM_DIR/gos/${binary_pkg}" ]]; then
    log "go ${binary_pkg} already installed via gvm"
    atomic_symlink "$GVM_DIR/gos/${binary_pkg}" "$HOME/.local/go"
    summary_skip "go ${binary_pkg} already installed"
    return 0
  fi

  # gvm sources files that reference unbound vars; relax 'set -u' for it.
  if ! run_installer gvm-go bash -c "
    set +u
    source '$GVM_DIR/scripts/gvm'
    gvm install '$binary_pkg' -B || gvm install '$binary_pkg'
    gvm use '$binary_pkg' --default
  "; then
    summary_fail "go: gvm install ${binary_pkg} failed"
    return 1
  fi

  if [[ ! -d "$GVM_DIR/gos/${binary_pkg}" ]]; then
    summary_fail "go: gvm finished but ${binary_pkg} is missing"
    return 1
  fi

  touch "$marker"
  atomic_symlink "$GVM_DIR/gos/${binary_pkg}" "$HOME/.local/go"
  summary_ok "go ${binary_pkg} installed via gvm (symlink: \$HOME/.local/go -> gos/${binary_pkg})"
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

# ---------- Java (via SDKMAN!) ---------------------------------------
# https://sdkman.io
# SDKMAN! manages the JDK in ~/.sdkman/candidates/java/<version> with a
# `current` symlink that the dotfiles point JAVA_HOME at.

SDKMAN_DIR="$HOME/.sdkman"
JDK_FEATURE_VERSION="${JDK_FEATURE_VERSION:-21}"
JDK_DISTRIBUTION="${JDK_DISTRIBUTION:-tem}"   # Eclipse Temurin

ensure_sdkman() {
  if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    return 0
  fi

  if is_dry_run; then
    printf '[DRY-RUN] curl -fsSL https://get.sdkman.io | bash\n'
    return 0
  fi

  # SDKMAN's installer respects $SDKMAN_DIR.
  if ! run_installer sdkman bash -c "
    export SDKMAN_DIR='$SDKMAN_DIR'
    curl -fsSL https://get.sdkman.io | bash -s -- -y
  "; then
    return 1
  fi
}

sdkman_latest_java_id() {
  # Asks SDKMAN for the latest version matching <feature>.* and the desired
  # distribution (e.g. 21.0.5-tem).
  bash -c "
    set +u
    export SDKMAN_DIR='$SDKMAN_DIR'
    source '$SDKMAN_DIR/bin/sdkman-init.sh'
    sdk list java 2>/dev/null \
      | awk -v dist='$JDK_DISTRIBUTION' -v feat='$JDK_FEATURE_VERSION' '
          \$NF ~ (\"^\" feat \"[.\\\\-].*-\" dist \"\$\") {print \$NF; exit}
        '
  "
}

install_java() {
  if skip_if_env java; then summary_skip "java (SKIP_JAVA=1)"; return 0; fi

  if ! ensure_sdkman; then
    summary_fail "java: could not install SDKMAN!"
    return 1
  fi

  if is_dry_run; then
    printf '[DRY-RUN] sdk install java <latest-%s-%s>\n' "$JDK_FEATURE_VERSION" "$JDK_DISTRIBUTION"
    summary_ok "java via SDKMAN (dry-run)"
    return 0
  fi

  local jid
  jid="$(sdkman_latest_java_id || true)"
  if [[ -z "$jid" ]]; then
    summary_fail "java: could not resolve a JDK ${JDK_FEATURE_VERSION}-${JDK_DISTRIBUTION} candidate via SDKMAN"
    return 1
  fi

  local cdir="$SDKMAN_DIR/candidates/java/$jid"
  if [[ -d "$cdir" ]]; then
    log "JDK $jid already installed via SDKMAN at $cdir"
  else
    if ! run_installer sdkman-java bash -c "
      set +u
      export SDKMAN_DIR='$SDKMAN_DIR'
      source '$SDKMAN_DIR/bin/sdkman-init.sh'
      yes n | sdk install java '$jid' || sdk install java '$jid' < /dev/null
    "; then
      summary_fail "java: SDKMAN failed installing $jid"
      return 1
    fi
  fi

  # Ensure the SDKMAN 'current' symlink points to our version, then expose
  # it via the path the dotfiles already expect.
  if ! run_installer sdkman-default bash -c "
    set +u
    export SDKMAN_DIR='$SDKMAN_DIR'
    source '$SDKMAN_DIR/bin/sdkman-init.sh'
    sdk default java '$jid'
  "; then
    warn "java: could not set $jid as the SDKMAN default"
  fi

  ensure_dir "$LOCAL_LIB"
  atomic_symlink "$SDKMAN_DIR/candidates/java/current" "$LOCAL_LIB/jdk"
  summary_ok "java $jid installed via SDKMAN (symlink: $LOCAL_LIB/jdk -> sdkman/current)"
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
    printf '[DRY-RUN] PNPM_HOME=%q SHELL=$(command -v sh) curl -fsSL https://get.pnpm.io/install.sh | sh -s -- -y\n' \
      "$HOME/.local/share/pnpm"
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
  local step="$1" total="$2" lang="$3"
  progress_bar "$((step - 1))" "$total" "starting $lang"
  if ! "install_${lang}"; then
    warn "${lang} installer failed (continuing with the rest)"
  fi
  progress_bar "$step" "$total" "$lang done"
}

main() {
  log "=== languages.sh === (DRY_RUN=${DRY_RUN:-0})"
  ensure_dir "$LOCAL_BIN"
  ensure_dir "$LOCAL_LIB"
  ensure_dir "$LOCAL_OPT"
  ensure_dir "$CACHE_ROOT"

  local total="${#LANGUAGES[@]}"
  local i=0 lang
  for lang in "${LANGUAGES[@]}"; do
    i=$((i + 1))
    run_one "$i" "$total" "$lang"
  done

  if print_summary "Languages (vm)"; then
    return 0
  fi
  return 1
}

main "$@"
