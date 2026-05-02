# ~/.bashrc - host (Fedora Silverblue / Atomic)
# Interactive bash configuration for the host.

[[ $- != *i* ]] && return

if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

PS1='[\u@\h \W]\$ '

alias la='ls -lah'
alias ll='ls -lh'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'

alias dbe='distrobox enter'
alias dbl='distrobox list'
alias dbf='distrobox enter fedora'

alias fpu='flatpak --user'
alias fpus='flatpak --user search'
alias fpui='flatpak --user install -y'
alias fpuu='flatpak --user uninstall'
alias fpuup='flatpak --user update -y'
alias fpul='flatpak list --user'

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
