# ~/.zshrc - user shell on CachyOS and in the Fedora Distrobox.
# Shared PATH and environment live in ~/.profile.

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell zsh)"
    fnm use >/dev/null 2>&1
fi

export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

export ZSH="$HOME/.oh-my-zsh"

plugins=(git)
if [ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]; then
    plugins+=(zsh-autosuggestions)
fi
if [ -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ]; then
    plugins+=(zsh-syntax-highlighting)
fi

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi

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

if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
    export VISUAL=nvim
else
    export EDITOR=vim
    export VISUAL=vim
fi

if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion zsh)"
fi

if command -v pnpm >/dev/null 2>&1; then
    alias npm="pnpm"
    alias npx="pnpm dlx"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Use Claude CLI with the DeepSeek backend; the key stays in the environment.
claude() {
    ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" \
        ANTHROPIC_AUTH_TOKEN="${DEEPSEEK_API_KEY:?DEEPSEEK_API_KEY must be set}" \
        ANTHROPIC_MODEL="deepseek-v4-pro[1m]" \
        ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]" \
        ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]" \
        ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash" \
        CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash" \
        CLAUDE_CODE_EFFORT_LEVEL="max" \
        command claude "$@"
}

alias fedora='distrobox enter fedora -- zsh'

# Syntax highlighting must load after widgets, completion, and aliases.
if (( !$+functions[_zsh_highlight] )) && [ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Attach only in the Fedora container and never inside tmux or a non-interactive command.
if [[ ${CONTAINER_ID:-} == fedora && -z ${TMUX:-} && -z ${ZSH_EXECUTION_STRING:-} && -o interactive && -t 0 && -t 1 ]] \
    && command -v tmux >/dev/null 2>&1; then
    tmux new-session -A -s fedora
fi
