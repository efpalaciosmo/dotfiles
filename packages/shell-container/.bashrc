# ~/.bashrc - macOS dotfiles
# Interactive bash configuration. Shared PATH and environment live in ~/.profile.

[[ $- != *i* ]] && return

if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

if command -v brew >/dev/null 2>&1; then
    _brew_prefix="$(brew --prefix 2>/dev/null || true)"
    for _completion in \
        "$_brew_prefix/etc/profile.d/bash_completion.sh" \
        "$_brew_prefix/etc/bash_completion"; do
        if [ -f "$_completion" ]; then
            # shellcheck disable=SC1090
            . "$_completion"
            break
        fi
    done
    unset _completion _brew_prefix
fi

if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
    export VISUAL="nvim"
fi

if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion bash)"
fi

if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell bash)"
fi

if command -v pnpm >/dev/null 2>&1; then
    alias npm="pnpm"
    alias npx="pnpm dlx"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    PS1='[\u@\h \W]\$ '
fi
