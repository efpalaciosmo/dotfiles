# ~/.profile - Arch Linux host
# Loaded by login shells. Keep it POSIX-compatible.

# Local user binaries (Starship, stown, language tools, etc.)
if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) PATH="$HOME/.local/bin:$PATH" ;;
    esac
fi

# fnm (Fast Node Manager) and pnpm live in user-local data dirs.
if [ -d "$HOME/.local/share/fnm" ]; then
    case ":$PATH:" in
        *":$HOME/.local/share/fnm:"*) ;;
        *) PATH="$HOME/.local/share/fnm:$PATH" ;;
    esac
fi

PNPM_HOME="$HOME/.local/share/pnpm"
if [ -d "$PNPM_HOME" ]; then
    case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) PATH="$PNPM_HOME:$PATH" ;;
    esac
fi
export PNPM_HOME

# Cargo (in case the user installs Rust via rustup later).
if [ -d "$HOME/.cargo/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.cargo/bin:"*) ;;
        *) PATH="$HOME/.cargo/bin:$PATH" ;;
    esac
fi

export PATH

# Editor on the host: Arch ships nvim by default in this profile.
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="${EDITOR:-nvim}"
    export VISUAL="${VISUAL:-nvim}"
elif command -v vim >/dev/null 2>&1; then
    export EDITOR="${EDITOR:-vim}"
    export VISUAL="${VISUAL:-vim}"
elif command -v nano >/dev/null 2>&1; then
    export EDITOR="${EDITOR:-nano}"
    export VISUAL="${VISUAL:-nano}"
fi

# XDG defaults (most apps fall back fine, but mako / niri / etc. read these).
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
. "$HOME/.cargo/env"
