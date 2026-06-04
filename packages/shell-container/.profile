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

if command -v brew >/dev/null 2>&1; then
    _brew_prefix="$(brew --prefix 2>/dev/null || true)"
    if [ -n "$_brew_prefix" ]; then
        _brew_binutils_bin="$_brew_prefix/opt/binutils/bin"
        _brew_gcc_bin="$_brew_prefix/opt/gcc/bin"
        _brew_glibc_prefix="$_brew_prefix/opt/glibc"
        _brew_linux_headers_prefix="$_brew_prefix/opt/linux-headers@6.8"
        _brew_llvm_bin="$_brew_prefix/opt/llvm/bin"
        _brew_rustup_bin="$_brew_prefix/opt/rustup/bin"

        _prepend_path_first "$_brew_prefix/bin"
        _prepend_path_first "$_brew_prefix/sbin"
        _prepend_path_first "$_brew_prefix/opt/make/libexec/gnubin"
        _prepend_path_first "$_brew_gcc_bin"
        _prepend_path_first "$_brew_llvm_bin"
        _prepend_path_first "$_brew_binutils_bin"
        _prepend_path_first "$_brew_glibc_prefix/sbin"
        _prepend_path_first "$_brew_glibc_prefix/bin"
        _prepend_path_first "$_brew_rustup_bin"

        _brew_gcc=""
        _brew_gxx=""
        for _brew_gcc_candidate in "$_brew_gcc_bin"/gcc-[0-9]*; do
            [ -x "$_brew_gcc_candidate" ] || continue
            _brew_gcc="$_brew_gcc_candidate"
            _brew_gcc_version="${_brew_gcc##*-}"
            _brew_gxx="$_brew_gcc_bin/g++-$_brew_gcc_version"
            break
        done

        if [ -n "${_brew_gcc:-}" ]; then
            CC="$_brew_gcc"
            [ -x "$_brew_gxx" ] && CXX="$_brew_gxx"
            export CC CXX
        elif [ -x "$_brew_llvm_bin/clang" ]; then
            CC="$_brew_llvm_bin/clang"
            CXX="$_brew_llvm_bin/clang++"
            export CC CXX
        fi

        if [ -d "$_brew_glibc_prefix/lib" ]; then
            LIBRARY_PATH="$_brew_glibc_prefix/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
            LDFLAGS="-L$_brew_glibc_prefix/lib${LDFLAGS:+ $LDFLAGS}"
            export LIBRARY_PATH LDFLAGS
        fi

        if [ -d "$_brew_glibc_prefix/include" ]; then
            CPPFLAGS="-I$_brew_glibc_prefix/include${CPPFLAGS:+ $CPPFLAGS}"
            export CPPFLAGS
        fi

        if [ -d "$_brew_linux_headers_prefix/include" ]; then
            CPPFLAGS="-I$_brew_linux_headers_prefix/include${CPPFLAGS:+ $CPPFLAGS}"
            export CPPFLAGS
        fi

        [ -x "$_brew_binutils_bin/ld" ] && LD="$_brew_binutils_bin/ld"
        [ -x "$_brew_binutils_bin/ar" ] && AR="$_brew_binutils_bin/ar"
        [ -x "$_brew_binutils_bin/as" ] && AS="$_brew_binutils_bin/as"
        [ -x "$_brew_binutils_bin/objdump" ] && OBJDUMP="$_brew_binutils_bin/objdump"
        export LD AR AS OBJDUMP
    fi
fi

export PATH

unset -f _prepend_path
unset -f _prepend_path_first
unset -f _setup_homebrew
unset _brew _brew_prefix _brew_binutils_bin _brew_gcc _brew_gcc_bin _brew_gcc_candidate _brew_gcc_version _brew_glibc_prefix _brew_gxx _brew_linux_headers_prefix _brew_llvm_bin _brew_rustup_bin
