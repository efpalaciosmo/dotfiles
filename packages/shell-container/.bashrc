# ~/.bashrc - Tumbleweed Distrobox container
# Interactive bash configuration for the dev container.
#
# Toolchain PATHs and env vars live in ~/.profile (POSIX). This file only
# contains bash-specific code (hooks, completions, prompt).

[[ $- != *i* ]] && return

if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# ---- Editor ---------------------------------------------------------
if command -v code-insiders >/dev/null 2>&1; then
    export EDITOR="code-insiders --wait"
    export VISUAL="code-insiders --wait"
elif command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
    export VISUAL="nvim"
fi

# ---- Aliases --------------------------------------------------------

alias la='ls -lah'
alias ll='ls -lh'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'

alias logs="podman logs"
alias dpush="podman push"
alias db="podman build"
alias di="podman image"
alias dc="podman container"
alias dps="podman ps"
alias dpsa="podman ps -a"

# Python / uv
alias uvr="uv run"
alias uvs="uv sync"
alias uva="uv add"
alias uvad="uv add --dev"
alias uvrem="uv remove"
alias uvi="uv init"
alias uvlock="uv lock"

# ---- Toolchain hooks (bash-specific) --------------------------------

# uv autocompletion (bash)
if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion bash)"
fi

# fnm hook (bash)
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell bash)"
fi

# Starship prompt (bash)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# Fallback prompt if starship is not available yet.
if ! command -v starship >/dev/null 2>&1; then
    PS1='[\u@\h \W]\$ '
fi

# gvm and SDKMAN_DIR are initialised in ~/.profile (POSIX, shared with zsh).
# The marker below is here so the SDKMAN installer's idempotency check sees a
# reference to SDKMAN_DIR in this file and does NOT auto-append a second init
# block with hardcoded paths. Do not remove.
# SDKMAN_DIR is configured in ~/.profile.
if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.cargo/env"
fi
