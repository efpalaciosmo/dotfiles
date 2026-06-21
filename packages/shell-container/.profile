# ~/.profile - macOS dotfiles
# POSIX-compatible environment loaded by login shells and sourced from
# .zshrc/.bashrc. Shell-specific hooks live in those rc files.

_prepend_path() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

_prepend_path_first() {
    [ -d "$1" ] || return 0
    PATH="$1:$PATH"
}

_setup_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        eval "$(brew shellenv)"
        return 0
    fi

    for _brew in \
        /opt/homebrew/bin/brew \
        /usr/local/bin/brew; do
        if [ -x "$_brew" ]; then
            eval "$("$_brew" shellenv)"
            return 0
        fi
    done
}

_setup_homebrew

_prepend_path "$HOME/bin"
_prepend_path "$HOME/.local/bin"

CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
_prepend_path "$CARGO_HOME/bin"
export CARGO_HOME

_prepend_path "$HOME/.juliaup/bin"

PNPM_HOME="$HOME/.local/share/pnpm"
_prepend_path "$PNPM_HOME/bin"
export PNPM_HOME

_prepend_path "/Library/TeX/texbin"

if command -v brew >/dev/null 2>&1; then
    _brew_prefix="$(brew --prefix 2>/dev/null || true)"
    if [ -n "$_brew_prefix" ]; then
        _brew_ffmpeg_full_bin="$_brew_prefix/opt/ffmpeg-full/bin"
        _brew_imagemagick_full_bin="$_brew_prefix/opt/imagemagick-full/bin"
        _brew_llvm_bin="$_brew_prefix/opt/llvm/bin"

        _prepend_path_first "$_brew_prefix/bin"
        _prepend_path_first "$_brew_prefix/sbin"
        _prepend_path_first "$_brew_prefix/opt/make/libexec/gnubin"
        _prepend_path_first "$_brew_prefix/opt/gnu-tar/libexec/gnubin"
        _prepend_path_first "$_brew_llvm_bin"
        _prepend_path_first "$_brew_ffmpeg_full_bin"
        _prepend_path_first "$_brew_imagemagick_full_bin"

        if [ -x "$_brew_llvm_bin/clang" ]; then
            CC="$_brew_llvm_bin/clang"
            CXX="$_brew_llvm_bin/clang++"
            export CC CXX
        fi
    fi
fi

export PATH

unset -f _prepend_path
unset -f _prepend_path_first
unset -f _setup_homebrew
unset _brew _brew_prefix _brew_ffmpeg_full_bin _brew_imagemagick_full_bin _brew_llvm_bin
