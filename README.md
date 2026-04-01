# Dotfiles

Personal dotfiles repository for Linux development environment setup. Includes configuration for shell (Zsh), editor (Neovim), prompt (Starship), and automated installation of development tools.

## 📋 Contents

This repository manages:

- **Shell Configuration**: Zsh with Oh-My-Zsh, plugins, and custom aliases
- **Editor**: Neovim with keymaps, options, and LSP configuration
- **Prompt**: Starship with multi-language support
- **Development Tools**:
  - Python (via `uv` package manager)
  - Node.js + npm/pnpm (via `fnm`)
  - Go, Java, Julia
  - Docker, Git
  - CLI utilities: fzf, ripgrep, fd, bat, eza, etc.

## 🚀 Quick Start

### Prerequisites

- Linux (Fedora or OpenSUSE)
- `git` and `curl`
- `sudo` access (for package installation)

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Run the setup script:
   ```bash
   ./setup.sh fedora  # or opensuse
   ```

   The script will:
   - Install all required system packages
   - Configure Git globally
   - Set up symlinks for configuration files
   - Install development tools (Python, Node.js, Go, Java, Julia, etc.)

3. Restart your shell:
   ```bash
   exec zsh
   ```

## 📁 Directory Structure

```
.dotfiles/
├── setup.sh              # Main setup script
├── zshrc                 # Zsh configuration
├── config/
│   ├── starship.toml     # Starship prompt configuration
│   └── nvim/             # Neovim configuration
│       ├── init.lua      # Main Neovim config
│       └── lua/
│           ├── keymap.lua    # Keybindings
│           └── option.lua    # Neovim options
└── system/
    ├── init.sh           # Helper functions and utilities
    └── apps.sh           # Application installation scripts
```

## 🔧 Configuration

### Zsh

Edit [zshrc](zshrc) to customize:
- Oh-My-Zsh plugins
- Command aliases
- Environment variables
- Shell functions

### Neovim

Configuration files are in `config/nvim/`:
- [init.lua](config/nvim/init.lua): Entry point
- [keymap.lua](config/nvim/lua/keymap.lua): Keybindings
- [option.lua](config/nvim/lua/option.lua): Editor settings

### Starship Prompt

Edit [config/starship.toml](config/starship.toml) to customize the prompt appearance and behavior.

## 🔑 SSH Configuration

The setup script symlinks your SSH directory to `~/.ssh`. To use it:

1. Place your SSH keys in the `ssh/` directory
2. Public keys should have the `.pub` extension
3. Private keys should be readable by your user only
4. Permissions are automatically set during setup

Example:
```
ssh/
├── id_rsa          # Private key (400)
├── id_rsa.pub      # Public key (644)
├── config          # SSH config file
└── known_hosts     # Known hosts file
```

## 📦 Installed Tools

### Runtime Environments
- **Python 3.12**: Managed by `uv`
- **Node.js LTS**: Managed by `fnm`
- **Go 1.26.1**: Standalone installation
- **Java 17**: Standalone installation
- **Julia**: Latest stable release via `juliaup`

### Package Managers
- **uv**: Python package manager with shell completion
- **fnm**: Fast Node Manager for Node.js version management
- **pnpm**: Fast npm-compatible package manager

### CLI Tools
- `bat`: Cat with syntax highlighting
- `eza`: Modern ls replacement
- `fzf`: Fuzzy finder
- `ripgrep`: Fast grep alternative
- `fd`: User-friendly find replacement
- `tree`: Directory tree viewer
- `jq`: JSON processor
- `gh`: GitHub CLI
- `tldr`: Simplified man pages
- `fastfetch`: System information tool
- `btop`: System monitor

## 🛠️ Development

### Making Changes

1. Edit configuration files directly in the repository
2. Test changes before committing
3. Commit with descriptive messages

### Updating Tools

Most tools are installed to `~/.local/`:
- **Go**: `~/.local/go`
- **Java**: `~/.local/lib/jdk-17`
- **Gradle**: `~/.local/opt/gradle-*`
- **Starship**: `~/.local/bin/starship`

To update, manually download new versions or modify the installation scripts.

## 📝 Notes

- The setup script supports **Fedora** and **OpenSUSE**. Contributions for other distros are welcome.
- Some installations (Go, Java) might require restarting your shell to pick up environment variables.
- The `zshrc` includes completion configs for `uv` and `fnm` - ensure these tools are installed before using them.

## 🐳 Testing with Podman

Test the setup script in isolated containers before running on your system. This section provides instructions for Fedora 44 and OpenSUSE Leap.

### Prerequisites

- `podman` installed and running
- This repository cloned locally

### Testing on Fedora 44

1. **Start a Fedora 44 container**:
   ```bash
   podman run -it --name fedora-test fedora:44 /bin/bash
   ```

2. **Inside the container, install basic utilities**:
   ```bash
   dnf update -y && dnf install -y sudo wget curl git
   ```

3. **Create the test user**:
   ```bash
   useradd -m -s /bin/bash efpalaciosmo
   echo "efpalaciosmo:password123" | chpasswd
   usermod -aG wheel efpalaciosmo  # Add to sudoers
   ```

4. **Switch to the test user**:
   ```bash
   su - efpalaciosmo
   ```

5. **Clone the dotfiles repository**:
   ```bash
   cd ~
   git clone /path/to/your/dotfiles ~/.dotfiles
   cd ~/.dotfiles
   ```
   
   *Note: If cloning from GitHub instead, use:*
   ```bash
   git clone https://github.com/yourusername/dotfiles ~/.dotfiles
   ```

6. **Make the setup script executable and run it**:
   ```bash
   chmod +x setup.sh
   ./setup.sh fedora
   ```

7. **Verify the installation**:
   ```bash
   exec zsh
   starship --version
   nvim --version
   uv --version
   fnm --version
   go version
   java -version
   julia --version
   ```

8. **Exit the container**:
   ```bash
   exit
   exit  # Exit again to close container
   ```

### Testing on OpenSUSE Leap

1. **Start an OpenSUSE Leap container**:
   ```bash
   podman run -it --name opensuse-test opensuse/leap /bin/bash
   ```

2. **Inside the container, install basic utilities**:
   ```bash
   zypper refresh && zypper install -y sudo wget curl git
   ```

3. **Create the test user**:
   ```bash
   useradd -m -s /bin/bash efpalaciosmo
   echo "efpalaciosmo:password123" | chpasswd
   usermod -aG wheel efpalaciosmo  # Add to sudoers
   ```

4. **Switch to the test user**:
   ```bash
   su - efpalaciosmo
   ```

5. **Clone the dotfiles repository**:
   ```bash
   cd ~
   git clone /path/to/your/dotfiles ~/.dotfiles
   cd ~/.dotfiles
   ```

6. **Make the setup script executable and run it**:
   ```bash
   chmod +x setup.sh
   ./setup.sh opensuse
   ```

7. **Verify the installation**:
   ```bash
   exec zsh
   starship --version
   nvim --version
   uv --version
   fnm --version
   go version
   java -version
   julia --version
   ```

8. **Exit the container**:
   ```bash
   exit
   exit  # Exit again to close container
   ```

### Managing Test Containers

- **List all containers**:
  ```bash
  podman ps -a
  ```

- **Remove a test container**:
  ```bash
  podman rm fedora-test
  podman rm opensuse-test
  ```

- **Restart a container**:
  ```bash
  podman start -i fedora-test
  ```

### Tips for Testing

- Test with a fresh container each time to simulate a clean system
- If the script fails, check error messages and update the installation scripts as needed
- For persistent testing, create container volumes to preserve state between runs
- Use `podman logs` to review container execution logs

## 🤝 Contributing

Feel free to adapt this configuration for your needs. If you find improvements, you can:
1. Fork and customize
2. Create pull requests for general improvements

## 📄 License

These are personal dotfiles. Feel free to use as a reference for your own setup.

## 🆘 Troubleshooting

- **Command not found after installation**: Restart your shell with `exec zsh`
- **Permission denied on setup.sh**: Run `chmod +x setup.sh`
- **Julia not recognized**: Add `~/.juliaup/bin` to your PATH manually
- **fnm/uv autocompletion not working**: Restart your terminal session

For more help, check the individual configuration files or open an issue.
