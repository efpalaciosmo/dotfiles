# ~/.profile - user environment
# POSIX-compatible environment loaded by login shells and sourced from
# .bashrc and .zshrc. Shell-specific hooks live in those rc files.

_prepend_path() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

_append_path() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$PATH:$1" ;;
    esac
}

_prepend_path "$HOME/bin"
_prepend_path "$HOME/.local/bin"
_prepend_path "$HOME/.opencode/bin"

CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
_prepend_path "$CARGO_HOME/bin"
export CARGO_HOME

PNPM_HOME="$HOME/.local/share/pnpm"
_prepend_path "$PNPM_HOME/bin"
export PNPM_HOME

# .NET SDK + PAC CLI (Power Platform)
DOTNET_ROOT="$HOME/.dotnet"
_prepend_path "$DOTNET_ROOT"
_prepend_path "$DOTNET_ROOT/tools"
export DOTNET_ROOT

# fnm binary; the per-shell `fnm env` hook lives in .bashrc and .zshrc.
_prepend_path "$HOME/.local/share/fnm"

# libatomic for Node.js (not in the base image; extracted from the Fedora RPM)
if [ -d "$HOME/.local/lib" ]; then
    LD_LIBRARY_PATH="$HOME/.local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export LD_LIBRARY_PATH
fi

_append_path /opt/Sidra

export PATH

unset -f _prepend_path _append_path
