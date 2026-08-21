# ~/.bashrc - Fedora dotfiles
# Interactive Bash configuration. Shared PATH and environment live in ~/.profile.

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

if command -v pnpm >/dev/null 2>&1; then
    alias npm="pnpm"
    alias npx="pnpm dlx"
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

# Fedora's programmable completion definitions for Git, systemd, dnf, etc.
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
export PATH=/var/home/efpalaciosmo/.opencode/bin:$PATH
