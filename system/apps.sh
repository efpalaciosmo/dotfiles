#!/bin/sh -e
# shellcheck disable=SC2086

. ./init.sh

install_cli_dependencies() {
    case "$DISTRO" in
        fedora)
            DEPENDENCIES='tree unzip cmake make jq fd-find ripgrep zig neovim git zsh curl wget fastfetch btop gh fzf bat eza tldr clang llvm lldb'
            ;;
        opensuse)
            DEPENDENCIES='tree unzip cmake make jq fd ripgrep zig neovim git zsh curl wget fastfetch btop gh fzf bat eza tldr clang llvm lldb'
            ;;
    esac

    printf "%b\n" "${YELLOW}Installing CLI dependencies for ${DISTRO}...${RC}"
    install_packages $DEPENDENCIES
}

installUV() {
    ## Install uv (Python package manager)
    printf "%b\n" "${YELLOW}Installing uv (Python package manager)...${RC}"
    if command -v uv >/dev/null 2>&1; then
        printf "%b\n" "${GREEN}uv is already installed${RC}"
        uv --version
    else
        printf "%b\n" "${CYAN}Downloading and installing uv...${RC}"
        curl -LsSf https://astral.sh/uv/install.sh | sh
        printf "%b\n" "${GREEN}uv installed successfully${RC}"
        printf "%b\n" "${YELLOW}Note: uv autocompletion already configured in your zshrc${RC}"
    fi
}

installPythonLTS() {
    ## Install latest stable Python via uv
    printf "%b\n" "${YELLOW}Installing Python LTS via uv...${RC}"
    
    # Source uv for current session
    export PATH="$HOME/.cargo/bin:$PATH"
    
    if command -v uv >/dev/null 2>&1; then
        # Install latest stable Python
        printf "%b\n" "${CYAN}Installing latest stable Python...${RC}"
        uv python install 3.12
        uv python pin 3.12
        
    else
        printf "%b\n" "${RED}uv not found, please restart your terminal and run this script again${RC}"
    fi
}

installJulia() {
    ## Install latest stable Julia
    printf "%b\n" "${YELLOW}Installing latest stable Julia...${RC}"

    export PATH="$HOME/.juliaup/bin:$PATH"

    if command -v julia >/dev/null 2>&1 && julia --version 2>&1 | grep -q 'julia version'; then
        printf "%b\n" "${GREEN}Julia is already installed${RC}"
        julia --version
    else
        if command -v juliaup >/dev/null 2>&1; then
            printf "%b\n" "${CYAN}Using existing juliaup installation...${RC}"
        else
            printf "%b\n" "${CYAN}Downloading and installing juliaup...${RC}"
            curl -fsSL https://install.julialang.org | sh -s -- -y
        fi

        if command -v juliaup >/dev/null 2>&1; then
            printf "%b\n" "${CYAN}Installing Julia release channel...${RC}"
            juliaup add release
            juliaup default release
            printf "%b\n" "${GREEN}Julia installed successfully and set to the latest stable release${RC}"
            julia --version
        else
            printf "%b\n" "${RED}juliaup is not available after installation${RC}"
        fi
    fi
}

installFNM() {
    ## Install fnm (Fast Node Manager)
    printf "%b\n" "${YELLOW}Installing fnm (Fast Node Manager)...${RC}"
    if command -v fnm >/dev/null 2>&1; then
        printf "%b\n" "${GREEN}fnm is already installed${RC}"
        fnm --version
    else
        printf "%b\n" "${CYAN}Downloading and installing fnm...${RC}"
        curl -fsSL https://fnm.vercel.app/install | bash
        printf "%b\n" "${GREEN}fnm installed successfully${RC}"
        printf "%b\n" "${YELLOW}Note: fnm configuration already set up in your zshrc${RC}"
    fi
}

installNodeLTS() {
    ## Install latest LTS Node.js via fnm
    printf "%b\n" "${YELLOW}Installing Node.js LTS via fnm...${RC}"
    
    # Source fnm for current session
    export PATH="$HOME/.local/share/fnm:$PATH"
    if command -v fnm >/dev/null 2>&1; then
        eval "$(fnm env --use-on-cd)"
        
        # Install and use latest LTS
        fnm install --lts
        fnm use lts-latest
        fnm default lts-latest
        
        printf "%b\n" "${GREEN}Node.js LTS installed and set as default${RC}"
        node --version
        npm --version
        
        # Install useful global packages
        printf "%b\n" "${CYAN}Installing useful global npm packages...${RC}"
        npm install -g pnpm typescript
        
    else
        printf "%b\n" "${RED}fnm not found, please restart your terminal and run this script again${RC}"
    fi
}

installGolang() {
    ## Install Golang
    printf "%b\n" "${YELLOW}Installing Golang 1.26.1...${RC}"
    if command -v go >/dev/null 2>&1 && go version | grep -q "go1.26.1"; then
        printf "%b\n" "${GREEN}Golang 1.26.1 is already installed${RC}"
    else
        printf "%b\n" "${CYAN}Downloading and installing Golang...${RC}"
        go_arch="$(uname -m)"
        case "$go_arch" in
            x86_64) go_arch="amd64" ;;
            aarch64|arm64) go_arch="arm64" ;;
            *)
                printf "%b\n" "${RED}Unsupported architecture for Go: $go_arch${RC}"
                exit 1
                ;;
        esac

        rm -rf "$HOME/.local/go"
        mkdir -p "$HOME/.local/downloads"
        wget -q -O "$HOME/.local/downloads/go1.26.1.linux-${go_arch}.tar.gz" "https://go.dev/dl/go1.26.1.linux-${go_arch}.tar.gz"
        tar -C "$HOME/.local" -xzf "$HOME/.local/downloads/go1.26.1.linux-${go_arch}.tar.gz"
        rm -f "$HOME/.local/downloads/go1.26.1.linux-${go_arch}.tar.gz"
        printf "%b\n" "${GREEN}Golang 1.26.1 installed successfully. Make sure to restart your shell.${RC}"
    fi
}

installJava() {
    ## Install Oracle JDK 17 locally
    printf "%b\n" "${YELLOW}Installing Java 17 locally...${RC}"

    java_version="17.0.12"

    java_arch="$(uname -m)"
    case "$java_arch" in
        x86_64) java_arch="x64" ;;
        aarch64|arm64) java_arch="aarch64" ;;
        *)
            printf "%b\n" "${RED}Unsupported architecture for Java: $java_arch${RC}"
            exit 1
            ;;
    esac

    java_home="$HOME/.local/lib/jdk-17"
    java_download="$HOME/.local/downloads/jdk17.tar.gz"

    if command -v java >/dev/null 2>&1 && java -version 2>&1 | grep -q 'version "17'; then
        printf "%b\n" "${GREEN}Java 17 is already installed${RC}"
    else
        mkdir -p "$HOME/.local/downloads" "$HOME/.local/lib"
        tmp_dir="$(mktemp -d)"
        curl -fL -o "$java_download" "https://download.oracle.com/java/17/archive/jdk-${java_version}_linux-${java_arch}_bin.tar.gz"
        tar -C "$tmp_dir" -xzf "$java_download"
        rm -f "$java_download"
        rm -rf "$java_home"
        extracted_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
        mv "$extracted_dir" "$java_home"
        rm -rf "$tmp_dir"
        printf "%b\n" "${GREEN}Java 17 installed successfully. Restart your shell to pick up JAVA_HOME.${RC}"
    fi
}

installStarship() {
    ## Install Starship locally
    printf "%b\n" "${YELLOW}Installing Starship locally...${RC}"
    if command -v starship >/dev/null 2>&1; then
        printf "%b\n" "${GREEN}Starship is already installed${RC}"
    else
        mkdir -p "$HOME/.local/bin"
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
        printf "%b\n" "${GREEN}Starship installed successfully${RC}"
    fi
}

installGradle() {
    ## Install Gradle locally
    printf "%b\n" "${YELLOW}Installing Gradle locally...${RC}"

    gradle_version="8.14.3"
    gradle_home="$HOME/.local/opt/gradle-$gradle_version"
    gradle_download="$HOME/.local/downloads/gradle-$gradle_version-bin.zip"

    if command -v gradle >/dev/null 2>&1 && gradle --version 2>/dev/null | grep -q "Gradle $gradle_version"; then
        printf "%b\n" "${GREEN}Gradle $gradle_version is already installed${RC}"
    else
        mkdir -p "$HOME/.local/downloads" "$HOME/.local/opt"
        tmp_dir="$(mktemp -d)"
        curl -fL -o "$gradle_download" "https://services.gradle.org/distributions/gradle-$gradle_version-bin.zip"
        unzip -q "$gradle_download" -d "$tmp_dir"
        rm -f "$gradle_download"
        rm -rf "$gradle_home"
        extracted_dir="$tmp_dir/gradle-$gradle_version"
        mv "$extracted_dir" "$gradle_home"
        rm -rf "$tmp_dir"
        printf "%b\n" "${GREEN}Gradle $gradle_version installed successfully. Restart your shell to pick up GRADLE_HOME.${RC}"
    fi
}

setupShellEnhancements() {
    ## Check existing shell setup
    printf "%b\n" "${YELLOW}Checking shell configuration...${RC}"
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        printf "%b\n" "${GREEN}Oh My Zsh already installed and configured${RC}"
    else
        printf "%b\n" "${CYAN}Installing Oh My Zsh...${RC}"
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # Check if plugins are already installed
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    
    if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        printf "%b\n" "${GREEN}zsh-autosuggestions already installed${RC}"
    else
        printf "%b\n" "${CYAN}Installing zsh-autosuggestions...${RC}"
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    
    if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        printf "%b\n" "${GREEN}zsh-syntax-highlighting already installed${RC}"
    else
        printf "%b\n" "${CYAN}Installing zsh-syntax-highlighting...${RC}"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
    
    if command -v starship >/dev/null 2>&1; then
        printf "%b\n" "${GREEN}Starship prompt already configured${RC}"
    else
        printf "%b\n" "${YELLOW}Starship will be installed with the system package manager${RC}"
    fi
}

main() {
    printf "%b\n" "${GREEN}Starting applications and package managers installation...${RC}"
    
    checkEnv
    install_cli_dependencies
    
    # Install package managers
    installUV
    installJulia
    installFNM
    installGolang
    installJava
    installStarship
    installGradle
    
    # Install language versions
    installPythonLTS
    installNodeLTS
    
    setupShellEnhancements
    
    printf "%b\n" "${GREEN}All installations completed!${RC}"
    printf "%b\n" "${CYAN}Applications installed:${RC}"
    printf "%b\n" "${YELLOW}CLI Tools: tree, jq, fd, ripgrep, neovim, git, fzf, bat, btop, etc.${RC}"
    printf "%b\n" "${CYAN}Language versions installed:${RC}"
    printf "%b\n" "${YELLOW}  • Python 3.12 (LTS) via uv${RC}"
    printf "%b\n" "${YELLOW}  • Julia LTS via juliaup${RC}"
    printf "%b\n" "${YELLOW}  • Node.js LTS via fnm${RC}"
    printf "%b\n" "${YELLOW}  • Golang 1.26.1 via local install${RC}"
    printf "%b\n" "${YELLOW}  • Java 17 via local Oracle JDK${RC}"
    printf "%b\n" "${YELLOW}  • Gradle 8.14.3 via local install${RC}"
    printf "%b\n" "${CYAN}Your zshrc configuration is ready for Linux shells.${RC}"
}

main