# ~/.bashrc - interactive Bash on the host and in the Fedora Distrobox.
# Interactive Bash configuration. Shared PATH and environment live in ~/.profile.

[[ $- != *i* ]] && return

# Distrobox may launch Bash even when the container user's login shell is zsh.
# Keep non-interactive commands untouched.
if [[ ${CONTAINER_ID:-} == fedora && -z ${BASH_EXECUTION_STRING:-} && -t 0 && -t 1 ]] \
    && command -v zsh >/dev/null 2>&1; then
    exec zsh -l
fi

if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
elif [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell bash)"
    fnm use >/dev/null 2>&1
fi

export EDITOR=vim
export VISUAL=vim

if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion bash)"
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

# Native developer prompt: location, Git state, virtual environment and errors.
__prompt_command() {
    local exit_code=$?
    local reset='\[\e[0m\]'
    local dim='\[\e[2m\]'
    local blue='\[\e[38;5;75m\]'
    local cyan='\[\e[38;5;80m\]'
    local green='\[\e[38;5;114m\]'
    local yellow='\[\e[38;5;221m\]'
    local red='\[\e[38;5;203m\]'
    local git_info='' venv_info='' status_info=''
    local branch

    if branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) ||
        branch=$(git rev-parse --short HEAD 2>/dev/null); then
        local dirty=''
        [[ -n $(git status --porcelain --ignore-submodules=dirty 2>/dev/null) ]] && dirty='*'
        git_info=" ${yellow}git:${branch}${dirty}${reset}"
    fi

    if [[ -n ${VIRTUAL_ENV:-} ]]; then
        venv_info=" ${green}(${VIRTUAL_ENV##*/})${reset}"
    fi

    if ((exit_code != 0)); then
        status_info=" ${red}[${exit_code}]${reset}"
    fi

    PS1="${dim}┌─${reset}${cyan}\u@\h${reset} ${blue}\w${reset}${git_info}${venv_info}${status_info}\n${dim}└─${reset}${green}\\\$${reset} "
}

if [[ ${PROMPT_COMMAND[*]:-} != *'__prompt_command'* ]]; then
    PROMPT_COMMAND=(__prompt_command "${PROMPT_COMMAND[@]}")
fi

# Aliases and other settings
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'
alias getaudio='read -p "Enter YouTube URL: " url; yt-dlp -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0 -o "$HOME/Music/%(title)s.%(ext)s" "$url"'
alias dev='distrobox enter fedora'

# Programmable completion definitions when installed.
if [[ -z ${BASH_COMPLETION_VERSINFO:-} && -r /usr/share/bash-completion/bash_completion ]]; then
    . /usr/share/bash-completion/bash_completion
fi

# Friendlier completion and command-line editing.
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'
bind 'set menu-complete-display-prefix on'
bind 'TAB:menu-complete'
bind '"\e[Z":menu-complete-backward'

shopt -s checkwinsize globstar histappend
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000

# opencode
export PATH=/home/efpalaciosmo/.opencode/bin:$PATH

# .NET SDK + PAC CLI (Power Platform)
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$HOME/.dotnet:$HOME/.dotnet/tools:$PATH"

# fnm
FNM_PATH="/home/efpalaciosmo/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell bash)"
fi

# libatomic for Node.js (not in the base image; extracted from the Fedora RPM)
export LD_LIBRARY_PATH="$HOME/.local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
