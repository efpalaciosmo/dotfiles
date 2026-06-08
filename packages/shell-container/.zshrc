# ~/.zshrc - portable dotfiles
# Shared PATH and environment live in ~/.profile.

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

if command -v brew >/dev/null 2>&1; then
    _brew_prefix="$(brew --prefix 2>/dev/null || true)"
    if [ -d "$_brew_prefix/share/zsh/site-functions" ]; then
        fpath=("$_brew_prefix/share/zsh/site-functions" $fpath)
    fi
    unset _brew_prefix
fi

if [ -d /usr/share/zsh/site-functions ]; then
    fpath=(/usr/share/zsh/site-functions $fpath)
fi

export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

export ZSH="$HOME/.oh-my-zsh"

plugins=(
  git
)
if [ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]; then
    plugins+=(zsh-autosuggestions)
fi
if [ -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ]; then
    plugins+=(zsh-syntax-highlighting)
fi

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi

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

if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
    export VISUAL="nvim"
fi

if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion zsh)"
fi

if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell zsh)"
fi

if command -v pnpm >/dev/null 2>&1; then
    alias npm="pnpm"
    alias npx="pnpm dlx"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# LazyDocker usando Podman rootless
alias lazypodman="DOCKER_HOST=unix:///run/user/1000/podman/podman.sock lazydocker"

wifi() {
    case "$1" in
        list)
            nmcli dev wifi list
            ;;
        connect)
            if [ -z "$2" ] || [ -z "$3" ]; then
                printf 'Usage: wifi connect "SSID" "PASSWORD"\n' >&2
                return 1
            fi

            nmcli dev wifi connect "$2" password "$3"
            ;;
        *)
            printf 'Usage:\n  wifi list\n  wifi connect "SSID" "PASSWORD"\n' >&2
            return 1
            ;;
    esac
}

eval "$(zoxide init zsh)"
