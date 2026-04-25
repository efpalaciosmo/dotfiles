#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR"

. ./system/init.sh
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

print_warning() {
    printf "${YELLOW}⚠ $1${NC}\n"
}

validate_dotfiles_layout() {
    print_step "Validating dotfiles layout..."

    [ -f "$SCRIPT_DIR/system/init.sh" ] || { print_error "Missing file: system/init.sh"; exit 1; }
    [ -f "$SCRIPT_DIR/system/apps.sh" ] || { print_error "Missing file: system/apps.sh"; exit 1; }
    [ -f "$SCRIPT_DIR/zshrc" ] || { print_error "Missing file: zshrc"; exit 1; }
    [ -f "$SCRIPT_DIR/config/starship.toml" ] || { print_error "Missing file: config/starship.toml"; exit 1; }

    if [ ! -d "$SCRIPT_DIR/config/nvim" ]; then
        print_warning "config/nvim not found, Neovim config symlink will be skipped"
    fi

    print_success "Dotfiles layout validated"
}

setup_git_config() {
    print_step "Configuring Git..."

    if ! command -v git >/dev/null 2>&1; then
        print_warning "git is not available yet, skipping git configuration"
        return
    fi

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

    print_success "Directories created"
}

setup_symlinks() {
    print_step "Setting up configuration symlinks..."

    safe_link() {
        src="$1"
        dst="$2"

        if [ -L "$dst" ]; then
            rm "$dst"
        elif [ -e "$dst" ]; then
            backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
            mv "$dst" "$backup"
            print_warning "Backed up existing $dst to $backup"
        fi

        ln -s "$src" "$dst"
    }

    if [ -d "$SCRIPT_DIR/config/nvim" ]; then
        safe_link "$SCRIPT_DIR/config/nvim" "$HOME/.config/nvim"
    fi

    if [ -f "$SCRIPT_DIR/config/starship.toml" ]; then
        safe_link "$SCRIPT_DIR/config/starship.toml" "$HOME/.config/starship.toml"
    fi

    if [ -f "$SCRIPT_DIR/zshrc" ]; then
        safe_link "$SCRIPT_DIR/zshrc" "$HOME/.zshrc"
    fi

    print_success "Symlinks created successfully"
}

install_applications() {
    print_step "Installing applications and development tools..."

    if [ "$(id -u)" -ne 0 ]; then
        if ! command -v sudo >/dev/null 2>&1; then
            print_error "sudo is required to install system packages"
            exit 1
        fi

        if [ ! -t 0 ]; then
            print_error "An interactive terminal is required to enter the sudo password"
            exit 1
        fi

        print_step "Requesting sudo authentication..."
        sudo -v
    fi

    sh "$SCRIPT_DIR/system/apps.sh"

    print_success "Applications installation completed"
}

final_setup() {
    print_step "Performing final setup..."
    print_success "Final setup completed"
}

show_completion_message() {
    print_header "Setup Complete"

    printf "${GREEN}Your Linux environment is now configured with:${NC}\n"
    printf "  ✅ Git configuration\n"
    printf "  ✅ Development tools (uv, JDK 17, Go 1.26.1, Julia, fnm, C/C++)\n"
    printf "  ✅ CLI productivity tools (git, fzf, bat, btop, etc.)\n"
    printf "  ✅ Neovim installation\n"
    printf "  ✅ Starship prompt\n"
    printf "  ✅ openSUSE package setup\n\n"

    printf "${YELLOW}Next Steps:${NC}\n"
    printf "  1. ${CYAN}Restart your terminal${NC} or run: source ~/.zshrc\n"
    printf "  2. ${CYAN}Test development tools${NC}:\n"
    printf "     - uv --version\n"
    printf "     - julia --version\n"
    printf "     - fnm --version\n"
    printf "     - java -version\n"
    printf "     - go version\n"
    printf "     - clang --version\n"
    printf "     - nvim --version\n\n"

    printf "${GREEN}Enjoy your optimized Linux development environment!${NC}\n"
}

main() {
    print_header "Linux Fresh Setup - Starting Configuration"

    checkEnv
    validate_dotfiles_layout
    create_directories
    install_applications
    setup_symlinks
    setup_git_config
    final_setup
    show_completion_message
}

main "$@"
