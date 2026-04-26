# ~/.profile - host (Fedora Silverblue / Atomic)
# Loaded by login shells. Keep it POSIX-compatible.

# Local user binaries (Distrobox, Starship, fonts tools, podman-compose, etc.)
if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) PATH="$HOME/.local/bin:$PATH" ;;
    esac
fi

# User flatpak data dir (so launchers and `flatpak run` work consistently).
if [ -d "$HOME/.local/share/flatpak/exports/share" ]; then
    case ":${XDG_DATA_DIRS:-}:" in
        *":$HOME/.local/share/flatpak/exports/share:"*) ;;
        *) XDG_DATA_DIRS="$HOME/.local/share/flatpak/exports/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" ;;
    esac
    export XDG_DATA_DIRS
fi

export PATH

# Editor on the host: prefer plain text editors, NOT code-insiders here.
# VS Code Insiders runs inside the `fedora` distrobox container.
if command -v nano >/dev/null 2>&1; then
    export EDITOR="${EDITOR:-nano}"
    export VISUAL="${VISUAL:-nano}"
fi
