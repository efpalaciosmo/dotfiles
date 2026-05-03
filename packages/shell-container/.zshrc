# ~/.zshrc - Distrobox container `fedora`
# Development environment.
#
# Toolchain PATHs and env vars live in ~/.profile (POSIX, shared with bash).
# This file only contains code that requires zsh.

# Note: do NOT wrap this in `emulate sh -c '...'`. SDKMAN's init scripts
# (sourced from .profile) use bash-isms like `[[ ... =~ ... ]]` that are
# invalid POSIX sh and trigger `parse error near '('` under sh emulation.
# zsh parses .profile (POSIX) just fine in native mode.
if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# ---- oh-my-zsh ------------------------------------------------------

export ZSH="$HOME/.oh-my-zsh"

plugins=(
  git
)
if [ -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ]; then
    plugins+=(zsh-syntax-highlighting)
fi
if [ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]; then
    plugins+=(zsh-autosuggestions)
fi

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# Ensure zsh completions exist even when oh-my-zsh is missing or skips compinit.
if (( ! $+_comps )); then
    autoload -Uz compinit
    compinit -i -d "${ZSH_COMPDUMP:-$HOME/.zcompdump}"
fi

setopt MENU_COMPLETE
setopt AUTO_LIST
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# ---- Editor ---------------------------------------------------------
# Prefer VS Code Insiders inside the container, fall back to nvim.
if command -v code-insiders >/dev/null 2>&1; then
    export EDITOR="code-insiders --wait"
    export VISUAL="code-insiders --wait"
elif command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
    export VISUAL="nvim"
fi

# ---- Aliases --------------------------------------------------------

# `podman` inside the container is bridged to the host during `make home`.
alias logs="podman logs"
alias dpush="podman push"
alias db="podman build"
alias di="podman image"
alias dc="podman container"
alias dps="podman ps"
alias dpsa="podman ps -a"

dlogin() {
  podman login -u metnetd docker.io
}

dp() {
    podman "$1" prune
}

# Python / uv
alias uvr="uv run"
alias uvs="uv sync"
alias uva="uv add"
alias uvad="uv add --dev"
alias uvrem="uv remove"
alias uvi="uv init"
alias uvlock="uv lock"

# Navigation
alias cls='clear'
alias la='ls -lah'
alias ll='ls -lh'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ---- Toolchain hooks (zsh-specific) ---------------------------------

# uv autocompletion (zsh)
if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion zsh)"
fi

# fnm hook (zsh)
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell zsh)"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# gvm and SDKMAN_DIR are initialised in ~/.profile (POSIX, shared with bash).
# The marker below is here so the SDKMAN installer's idempotency check sees a
# reference to SDKMAN_DIR in this file and does NOT auto-append a second init
# block with hardcoded paths. Do not remove.
# SDKMAN_DIR is configured in ~/.profile.
