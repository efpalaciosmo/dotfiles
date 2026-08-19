# ~/.profile - Fedora dotfiles
# POSIX-compatible environment loaded by login shells and sourced from
# .zshrc/.bashrc. Shell-specific hooks live in those rc files.

_prepend_path() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
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

export PATH

unset -f _prepend_path
