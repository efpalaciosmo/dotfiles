export ZSH="$HOME/.oh-my-zsh"

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    export PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/share/fnm" ] && [[ ":$PATH:" != *":$HOME/.local/share/fnm:"* ]]; then
  export PATH="$HOME/.local/share/fnm:$PATH"
fi

export EDITOR=nvim
export VISUAL=nvim

# Aliases

# Docker aliases
alias logs="docker logs"
alias dpush="docker push"
alias db="docker build"
alias di="docker image"
alias dc="docker container"
alias dps="docker ps"
alias dpsa="docker ps -a"

tree_ex() {
  tree -f -I "$1" "docker://docker.io/metnetd/$2"
}

dlogin() {
  docker login -u metnetd docker.io
}

# Python/uv aliases
alias uvr="uv run"
alias uvs="uv sync"
alias uva="uv add"
alias uvad="uv add --dev"
alias uvrem="uv remove"
alias uvi="uv init"
alias uvlock="uv lock"

# Navigation
alias cls='clear'
alias la='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Functions
# Docker prune function
dp() {
    docker "$1" prune
}

# fnm (Fast Node Manager) setup
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
fi

# uv Python package manager autocompletion
if command -v uv &> /dev/null; then
    eval "$(uv generate-shell-completion zsh)"
fi

# Zsh configuration
setopt MENU_COMPLETE
setopt AUTO_LIST
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

if [ -d "$HOME/.juliaup/bin" ]; then
  path=("$HOME/.juliaup/bin" $path)
  export PATH
fi

# <<< juliaup initialize <<<
# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Go (Golang)
export GOPATH="$HOME/go"
if [ -d "$HOME/.local/go" ]; then
  export GOROOT="$HOME/.local/go"
  case ":$PATH:" in
    *":$GOROOT/bin:"*) ;;
    *) export PATH="$GOROOT/bin:$GOPATH/bin:$PATH" ;;
  esac
fi

# Java
if [ -d "$HOME/.local/lib/jdk-17" ]; then
  export JAVA_HOME="$HOME/.local/lib/jdk-17"
  case ":$PATH:" in
    *":$JAVA_HOME/bin:"*) ;;
    *) export PATH="$JAVA_HOME/bin:$PATH" ;;
  esac
fi

# Gradle
export GRADLE_USER_HOME="$HOME/.gradle"
if [ -d "$HOME/.local/opt/gradle-8.14.3" ]; then
  export GRADLE_HOME="$HOME/.local/opt/gradle-8.14.3"
  case ":$PATH:" in
    *":$GRADLE_HOME/bin:"*) ;;
    *) export PATH="$GRADLE_HOME/bin:$PATH" ;;
  esac
fi

if [ -d "$HOME/.opencode" ]; then
  path=("$HOME/.opencode/bin" $path)
  export PATH
fi
