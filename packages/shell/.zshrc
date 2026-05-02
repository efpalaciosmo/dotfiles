# ~/.zshrc - host (Fedora Silverblue / Atomic)
# Interactive zsh configuration for the host.
#
# The host is intentionally lean: development tooling lives inside the
# `fedora` Distrobox container. See README.md for the rationale.

if [ -f "$HOME/.profile" ]; then
    emulate sh -c '. "$HOME/.profile"'
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    export ZSH="$HOME/.oh-my-zsh"
    plugins=(git)
    if [ -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ]; then
        plugins+=(zsh-syntax-highlighting)
    fi
    if [ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]; then
        plugins+=(zsh-autosuggestions)
    fi
    [ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"
fi

setopt MENU_COMPLETE
setopt AUTO_LIST
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

alias la='ls -lah'
alias ll='ls -lh'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'

alias dbe='distrobox enter'
alias dbl='distrobox list'
alias dbf='distrobox enter fedora'
alias dbrm='distrobox rm'

alias fpu='flatpak --user'
alias fpus='flatpak --user search'
alias fpui='flatpak --user install -y'
alias fpuu='flatpak --user uninstall'
alias fpuup='flatpak --user update -y'
alias fpul='flatpak list --user'

# rpm-ostree wrappers (read-only here; do NOT layer dev tooling on the host).
alias rosstatus='rpm-ostree status'
alias rosup='rpm-ostree upgrade'

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
