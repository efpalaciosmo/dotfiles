# ~/.profile - portable dotfiles
# POSIX-compatible environment loaded by login shells and sourced from
# .zshrc/.bashrc. Shell-specific hooks live in those rc files.

_prepend_path() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

_setup_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        eval "$(brew shellenv)"
        return 0
    fi

    for _brew in \
        /opt/homebrew/bin/brew \
        /usr/local/bin/brew \
        /home/linuxbrew/.linuxbrew/bin/brew; do
        if [ -x "$_brew" ]; then
            eval "$("$_brew" shellenv)"
            return 0
        fi
    done
}

_setup_homebrew

if command -v brew >/dev/null 2>&1; then
    _brew_prefix="$(brew --prefix 2>/dev/null || true)"
    if [ -n "$_brew_prefix" ]; then
        _prepend_path "$_brew_prefix/opt/make/libexec/gnubin"
        _prepend_path "$_brew_prefix/opt/llvm/bin"

        if [ -d "$_brew_prefix/opt/openjdk" ]; then
            JAVA_HOME="$_brew_prefix/opt/openjdk"
            _prepend_path "$JAVA_HOME/bin"
            export JAVA_HOME
        fi
    fi
fi

_prepend_path "$HOME/bin"
_prepend_path "$HOME/.local/bin"

GOPATH="$HOME/.go"
GOBIN="$GOPATH/bin"
_prepend_path "$GOBIN"
export GOPATH GOBIN

_prepend_path "$HOME/.juliaup/bin"

PNPM_HOME="$HOME/.local/share/pnpm"
_prepend_path "$PNPM_HOME"
export PNPM_HOME

if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.cargo/env"
fi

export PATH

unset -f _prepend_path
unset -f _setup_homebrew
unset _brew _brew_prefix
