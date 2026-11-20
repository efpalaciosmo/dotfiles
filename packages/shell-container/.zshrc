# ~/.zshrc - user shell on the host and in the Fedora Distrobox.
# Shared PATH and environment live in ~/.profile.
# Oh My Zsh and its plugins are installed under ~/.oh-my-zsh by scripts/install-zsh.sh
# (run by `make`); nothing here needs system packages.

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

if command -v fnm >/dev/null 2>&1; then
    if _fnm_env=$(fnm env --use-on-cd --shell zsh 2>/dev/null); then
        eval "$_fnm_env"
        fnm use >/dev/null 2>&1
    elif _fnm_node=$(fnm exec --using=default node -p 'process.execPath' 2>/dev/null); then
        # Restricted terminals may not permit fnm's runtime symlink; use Node directly.
        PATH="${_fnm_node%/*}:$PATH"
        export PATH
    fi
    unset _fnm_env _fnm_node
fi

export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

export ZSH="$HOME/.oh-my-zsh"

# The installer pins Oh My Zsh to a commit; `omz update` would fight that.
zstyle ':omz:update' mode disabled

plugins=(git)
if [ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]; then
    plugins+=(zsh-autosuggestions)
fi
# Keep syntax highlighting last: it must wrap every widget the other plugins define.
if [ -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ]; then
    plugins+=(zsh-syntax-highlighting)
fi

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# Fallbacks for a container that has the distribution packages instead.
if (( !$+functions[_zsh_autosuggest_start] )) && [ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if (( !$+_comps )); then
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

export EDITOR=vim
export VISUAL=vim

if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion zsh)"
fi

if command -v pnpm >/dev/null 2>&1; then
    alias npm="pnpm"
    alias npx="pnpm dlx"
fi

# Yazi: `y` opens it and, on quit, changes this shell to the directory you ended in.
if command -v yazi >/dev/null 2>&1; then
    y() {
        local tmp cwd
        tmp=$(mktemp -t yazi-cwd.XXXXXX) || return
        yazi "$@" --cwd-file="$tmp"
        if cwd=$(<"$tmp") && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
    }
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

alias fedora='distrobox enter fedora -- zsh'

# Syntax highlighting from the distribution, only when Oh My Zsh did not already load it.
if (( !$+functions[_zsh_highlight] )) && [ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Initialize the prompt after other plugins have finished configuring the shell.
if command -v starship >/dev/null 2>&1; then
    if _starship_init=$(starship init zsh); then
        eval "$_starship_init"
    else
        print -u2 -- '[dotfiles] Starship initialization failed; run starship init zsh for details.'
    fi
    unset _starship_init
else
    print -u2 -- '[dotfiles] Starship is missing from PATH.'
fi
