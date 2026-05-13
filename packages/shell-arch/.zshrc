# ~/.zshrc - Arch Linux host
# Interactive zsh configuration for the host.

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

# Ensure zsh completions exist even when oh-my-zsh is missing or skips compinit.
if (( ! $+_comps )); then
    autoload -Uz compinit
    compinit -i -d "${ZSH_COMPDUMP:-$HOME/.zcompdump}"
fi

# Pull in pacman-installed bash-style completions where available.
if [ -d /usr/share/zsh/site-functions ]; then
    fpath=(/usr/share/zsh/site-functions $fpath)
fi

setopt MENU_COMPLETE
setopt AUTO_LIST
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# History file (zsh defaults are stingy).
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

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

# podman
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

# uv autocompletion (zsh)
if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion zsh)"
fi

# fnm hook (zsh)
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell zsh)"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
