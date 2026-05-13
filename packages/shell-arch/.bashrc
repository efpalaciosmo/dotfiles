# ~/.bashrc - Arch Linux host
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

# pacman / system management
alias pacs='sudo pacman -S --needed'
alias pacu='sudo pacman -Syu'
alias pacr='sudo pacman -Rns'
alias pacq='pacman -Qs'
alias pacqi='pacman -Qi'
alias paclo='pacman -Qdt'
alias pacc='sudo pacman -Sc'

# flatpak (--user)
alias fpu='flatpak --user'
alias fpus='flatpak --user search'
alias fpui='flatpak --user install -y'
alias fpuu='flatpak --user uninstall'
alias fpuup='flatpak --user update -y'
alias fpul='flatpak list --user'

# podman (docker compatibility shim is optional on Arch)
alias pod='podman'
alias podc='podman compose'
alias podps='podman ps -a'

# Python / uv
alias uvr="uv run"
alias uvs="uv sync"
alias uva="uv add"
alias uvad="uv add --dev"
alias uvrem="uv remove"
alias uvi="uv init"
alias uvlock="uv lock"

# uv autocompletion (bash)
if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion bash)"
fi

# fnm hook (bash)
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell bash)"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
