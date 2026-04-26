# ~/.profile - Distrobox container `fedora`
# POSIX-compatible env. Loaded by login shells and sourced from
# .zshrc/.bashrc. Single source of truth for PATH and language toolchain
# environment variables; shell-specific bits (eval-style hooks) live in
# .zshrc / .bashrc.

# ---- helper: prepend $1 to PATH if it exists and isn't already there.
_prepend_path() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

# ---- Base user dirs -------------------------------------------------
_prepend_path "$HOME/bin"
_prepend_path "$HOME/.local/bin"

# ---- Go --------------------------------------------------------------
# Dot-prefixed GOPATH keeps $HOME tidy. GOROOT only exists when Go is
# installed locally by scripts/vm/languages.sh.
GOPATH="$HOME/.go"
GOBIN="$GOPATH/bin"
_prepend_path "$GOBIN"
if [ -d "$HOME/.local/go" ]; then
    GOROOT="$HOME/.local/go"
    _prepend_path "$GOROOT/bin"
    export GOROOT
fi
export GOPATH GOBIN

# ---- fnm (Fast Node Manager) ----------------------------------------
# The binary lives in $HOME/.local/share/fnm. Node versions live under
# XDG_DATA_HOME/fnm or equivalent; `fnm env` runs from shell-specific rc files.
_prepend_path "$HOME/.local/share/fnm"

# ---- Juliaup ---------------------------------------------------------
_prepend_path "$HOME/.juliaup/bin"

# ---- Java (JDK managed by languages.sh, versionless symlink) ---------
if [ -d "$HOME/.local/lib/jdk" ]; then
    JAVA_HOME="$HOME/.local/lib/jdk"
    _prepend_path "$JAVA_HOME/bin"
    export JAVA_HOME
fi

# ---- Gradle (symlink versionless) -----------------------------------
GRADLE_USER_HOME="$HOME/.gradle"
if [ -d "$HOME/.local/opt/gradle" ]; then
    GRADLE_HOME="$HOME/.local/opt/gradle"
    _prepend_path "$GRADLE_HOME/bin"
    export GRADLE_HOME
fi
export GRADLE_USER_HOME

# ---- pnpm ------------------------------------------------------------
PNPM_HOME="$HOME/.local/share/pnpm"
_prepend_path "$PNPM_HOME"
export PNPM_HOME

# ---- Rust / cargo ---------------------------------------------------
_prepend_path "$HOME/.cargo/bin"

# ---- opencode --------------------------------------------------------
_prepend_path "$HOME/.opencode/bin"

export PATH

unset -f _prepend_path
