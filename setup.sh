#!/bin/bash -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR"

. ./system/init.sh

DISTRO="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"

if [ -z "$DISTRO" ]; then
    printf "%b\n" "${RED}Usage: ./setup.sh <fedora|opensuse>${RC}"
    exit 1
fi

export DISTRO
NC="$RC"

print_header() {
    printf "\n${CYAN}=====================================${NC}\n"
    printf "${CYAN}$1${NC}\n"
    printf "${CYAN}=====================================${NC}\n"
}

print_step() {
    printf "${YELLOW}▶ $1${NC}\n"
}

print_success() {
    printf "${GREEN}✅ $1${NC}\n"
}

print_error() {
    printf "${RED}❌ $1${NC}\n"
}

make_scripts_executable() {
    print_step "Making all script files executable..."
    find "$SCRIPT_DIR" -name "*.sh" -type f -exec chmod +x {} \;
    print_success "All script files are now executable"
}

setup_git_config() {
    print_step "Configuring Git..."

    git config --global init.defaultBranch main
    git config --global user.name "Efrain Palacios Mosquera"
    git config --global user.email "efpalaciosmo@unal.edu.co"
    git config --global core.editor "nvim"
    git config --global pull.rebase false
    git config --global core.autocrlf input
    git config --global core.ignorecase false

    print_success "Git configuration completed"
}

create_directories() {
    print_step "Creating necessary directories..."

    mkdir -p "$HOME/.config"

    if [ -d "$HOME/.ssh" ] && [ ! -L "$HOME/.ssh" ]; then
        print_step "Backing up existing SSH directory..."
        mv "$HOME/.ssh" "$HOME/.ssh.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    print_success "Directories created"
}

setup_symlinks() {
    print_step "Setting up configuration symlinks..."

    [ -L "$HOME/.ssh" ] && rm "$HOME/.ssh"
    [ -L "$HOME/.config/nvim" ] && rm "$HOME/.config/nvim"
    [ -L "$HOME/.config/starship.toml" ] && rm "$HOME/.config/starship.toml"
    [ -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"

    ln -sf "$SCRIPT_DIR/ssh" "$HOME/.ssh"
    ln -sf "$SCRIPT_DIR/config/nvim" "$HOME/.config/nvim"
    ln -sf "$SCRIPT_DIR/config/starship.toml" "$HOME/.config/starship.toml"
    ln -sf "$SCRIPT_DIR/zshrc" "$HOME/.zshrc"

    if [ -d "$HOME/.ssh" ]; then
        chmod 700 "$HOME/.ssh"
        chmod 600 "$HOME/.ssh"/* 2>/dev/null || true
        chmod 644 "$HOME/.ssh"/*.pub 2>/dev/null || true
    fi

    print_success "Symlinks created successfully"
}

install_applications() {
    print_step "Installing applications and development tools..."

    cd "$SCRIPT_DIR/system"
    ./apps.sh
    cd "$SCRIPT_DIR"

    print_success "Applications installation completed"
}

configure_linux_settings() {
    print_step "Configuring Linux system settings..."

    cd "$SCRIPT_DIR/system"

    print_step "Cleaning up system..."
    ./cleanup.sh

    cd "$SCRIPT_DIR"

    print_success "Linux system configuration completed"
}

setup_shell() {
    print_step "Configuring shell environment..."

    zsh_path="$(command -v zsh || true)"
    if [ -n "$zsh_path" ] && [ "$SHELL" != "$zsh_path" ]; then
        print_step "Changing default shell to zsh..."
        chsh -s "$zsh_path"
    fi

    print_success "Shell configuration completed"
}

final_setup() {
    print_step "Performing final setup..."
    print_success "Final setup completed"
}

show_completion_message() {
    print_header "Setup Complete"

    printf "${GREEN}Your Linux environment is now configured with:${NC}\n"
    printf "  ✅ Git configuration\n"
    printf "  ✅ Development tools (uv, JDK 17, Go 1.26.1, Julia, fnm/Node.js, C/C++)\n"
    printf "  ✅ CLI productivity tools (git, fzf, bat, btop, etc.)\n"
    printf "  ✅ Neovim configuration\n"
    printf "  ✅ Starship prompt\n"
    printf "  ✅ System cleanup\n\n"

    printf "${YELLOW}Next Steps:${NC}\n"
    printf "  1. ${CYAN}Restart your terminal${NC} or run: source ~/.zshrc\n"
    printf "  2. ${CYAN}Check SSH setup${NC}: ls -la ~/.ssh/\n"
    printf "  3. ${CYAN}Test development tools${NC}:\n"
    printf "     - uv --version\n"
    printf "     - julia --version\n"
    printf "     - node --version\n"
    printf "     - java -version\n"
    printf "     - go version\n"
    printf "     - clang --version\n"
    printf "     - nvim --version\n\n"

    printf "${GREEN}Enjoy your optimized Linux development environment!${NC}\n"
}

main() {
    print_header "Linux Fresh Setup - Starting Configuration"

    if [ ! -f "$SCRIPT_DIR/system/init.sh" ]; then
        print_error "Please run this script from the dotfiles repository root"
        exit 1
    fi

    checkEnv
    make_scripts_executable
    setup_git_config
    create_directories
    setup_symlinks
    install_applications
    configure_linux_settings
    setup_shell
    final_setup
    show_completion_message
}

main "$@"