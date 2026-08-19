# ~/.bashrc - Fedora dotfiles
# Interactive bash configuration. Shared PATH and environment live in ~/.profile.

[[ $- != *i* ]] && return

if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
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

# opencode
export PATH=/home/efpalaciosmo/Projects/fedora/.opencode/bin:$PATH

# Pi
export PATH="/home/efpalaciosmo/Projects/fedora/.local/share/fnm/node-versions/v24.19.0/installation/bin:$PATH"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/efpalaciosmo/Projects/fedora/home/efpalaciosmo/Projects/fedora/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/efpalaciosmo/Projects/fedora/home/efpalaciosmo/Projects/fedora/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/efpalaciosmo/Projects/fedora/home/efpalaciosmo/Projects/fedora/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/efpalaciosmo/Projects/fedora/home/efpalaciosmo/Projects/fedora/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
