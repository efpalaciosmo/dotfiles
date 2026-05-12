# ~/.profile - Aeon host
# Loaded by login shells. Keep it POSIX-compatible.

# Local user binaries (Starship, stown, language tools, etc.)
if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) PATH="$HOME/.local/bin:$PATH" ;;
    esac
fi

# User Flatpak app commands exported by `flatpak --user`.
if [ -d "$HOME/.local/share/flatpak/exports/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.local/share/flatpak/exports/bin:"*) ;;
        *) PATH="$HOME/.local/share/flatpak/exports/bin:$PATH" ;;
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

# User flatpak data dir (so launchers and `flatpak run` work consistently).
if [ -d "$HOME/.local/share/flatpak/exports/share" ]; then
    case ":${XDG_DATA_DIRS:-}:" in
        *":$HOME/.local/share/flatpak/exports/share:"*) ;;
        *) XDG_DATA_DIRS="$HOME/.local/share/flatpak/exports/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" ;;
    esac
    export XDG_DATA_DIRS
fi

export PATH

# Editor on the host: use Aeon's default Vim when available.
if command -v vim >/dev/null 2>&1; then
    export EDITOR="${EDITOR:-vim}"
    export VISUAL="${VISUAL:-vim}"
elif command -v nano >/dev/null 2>&1; then
    export EDITOR="${EDITOR:-nano}"
    export VISUAL="${VISUAL:-nano}"
fi
