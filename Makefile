SHELL := /usr/bin/env bash

.PHONY: help doctor check home vm \
        fonts-home fonts-vm flatpaks distrobox \
        stown-home stown-vm \
        dry-run-home dry-run-vm \
        python-user-tools vscode-insiders podman-compose packages-vm starship-vm \
        languages-vm shell-plugins-vm

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-22s %s\n", $$1, $$2}'

# ---- Validation ------------------------------------------------------

doctor: ## Check environment (PATH, commands, host/distrobox context)
	@bash scripts/doctor.sh

check: ## Validate syntax (bash -n + shellcheck if available)
	@bash scripts/check.sh

# ---- Main profiles ---------------------------------------------------

home: ## Install/configure the Fedora Silverblue host (home profile)
	@bash scripts/home/install.sh

vm: ## Install/configure the Fedora Distrobox container (vm profile)
	@bash scripts/vm/install.sh

# ---- Dry-run mode ----------------------------------------------------

dry-run-home: ## Like 'home' but only prints important commands
	@DRY_RUN=1 bash scripts/home/install.sh

dry-run-vm: ## Like 'vm' but only prints important commands
	@DRY_RUN=1 bash scripts/vm/install.sh

# ---- Auxiliary targets (host) ----------------------------------------

fonts-home: ## Install Nerd Fonts on the host (~/.local/share/fonts)
	@bash scripts/home/fonts.sh

flatpaks: ## Configure user Flathub and install Flatpak apps
	@bash scripts/home/flatpaks.sh

distrobox: ## Install local distrobox and create the 'fedora' container
	@bash scripts/home/distrobox.sh

python-user-tools: ## Bootstrap pip --user and install 'stown'
	@bash scripts/home/python-user-tools.sh

stown-home: ## Apply home-profile dotfiles with stown
	@bash scripts/stown/apply.sh home

# ---- Auxiliary targets (vm) ------------------------------------------

fonts-vm: ## Install Nerd Fonts inside the container (~/.local/share/fonts)
	@bash scripts/vm/fonts.sh

packages-vm: ## Install Fedora packages with dnf inside the container
	@bash scripts/vm/packages-fedora.sh

vscode-insiders: ## Install VS Code Insiders inside the container
	@bash scripts/vm/vscode-insiders.sh

podman-compose: ## Install podman-compose into ~/.local/bin (container)
	@bash scripts/vm/podman-compose.sh

starship-vm: ## Install starship (prompt) into ~/.local/bin (container)
	@bash scripts/vm/starship.sh

languages-vm: ## Install Go/fnm/Julia/JDK/uv/Rust/Gradle/pnpm into ~/.local (container)
	@bash scripts/vm/languages.sh

shell-plugins-vm: ## Install oh-my-zsh + zsh-autosuggestions/syntax-highlighting (container)
	@bash scripts/vm/shell-plugins.sh

stown-vm: ## Apply vm-profile dotfiles with stown
	@bash scripts/stown/apply.sh vm
