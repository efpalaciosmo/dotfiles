SHELL := /usr/bin/env bash

VENV := $(CURDIR)/.venv
PIP := $(VENV)/bin/pip
ANSIBLE_PLAYBOOK := $(VENV)/bin/ansible-playbook
ANSIBLE_GALAXY := $(VENV)/bin/ansible-galaxy
INV := $(CURDIR)/inventory.ini
# Pass DRY_RUN=1 with --check for dry-run (see README).
CHECK := $(if $(filter 1,$(DRY_RUN)),--check,)
# Home pacman tasks use sudo. Flatpak only needs sudo when a system Flathub
# remote exists and should be removed.
HOME_BECOME := --ask-become-pass
FLATPAK_BECOME = $(shell flatpak remotes --system 2>/dev/null | awk '$$1 == "flathub" { print "--ask-become-pass"; exit }')

.PHONY: help setup doctor check verify home vm \
        packages-home fonts-home fonts-vm flatpaks distrobox \
        stown-home stown-vm \
        dry-run-home dry-run-vm \
        python-user-tools vscode-insiders podman-compose packages-vm starship-vm \
        starship-home language-home languages-home shell-plugins-home \
        languages-vm shell-plugins-vm

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-22s %s\n", $$1, $$2}'

setup: ## Create .venv, install ansible-core + collections, ensure inventory.ini
	@if [ ! -x "$(ANSIBLE_PLAYBOOK)" ]; then \
		python3 -m venv "$(VENV)"; \
		"$(PIP)" install -r requirements-ansible.txt; \
	fi
	@mkdir -p "$(CURDIR)/.ansible/collections"
	@"$(ANSIBLE_GALAXY)" collection install -r requirements.yml -p "$(CURDIR)/.ansible/collections"
	@test -f "$(INV)" || cp inventory.ini.example "$(INV)"

# ---- Validation ------------------------------------------------------

doctor: setup ## Check environment (PATH, commands, host/distrobox context)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook-doctor.yml

check: setup ## Ansible syntax-check (+ ansible-lint if installed)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=home --syntax-check
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=vm --syntax-check
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook-doctor.yml --syntax-check
	@command -v ansible-lint >/dev/null 2>&1 && ansible-lint -q . || true

# Partial Makefile targets must not pass `--tags foo,home` / `foo,vm` (Ansible OR would run the whole profile).
verify: check
	@! grep -E 'playbook\.yml.*--tags [^ ]+,(home|vm)' $(MAKEFILE_LIST) \
		|| (echo >&2 "verify: drop umbrella ,home/,vm from partial playbook invocations"; exit 1)
	@echo "verify: OK"

# ---- Main profiles ---------------------------------------------------

home: setup ## Install/configure the Arch Linux host (home profile)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=home --tags home $(HOME_BECOME) $(CHECK)

vm: setup ## Install/configure the Fedora Distrobox container (vm profile)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=vm --tags vm $(CHECK)

# ---- Dry-run mode ----------------------------------------------------

dry-run-home: ## Like 'home' in Ansible check mode
	@$(MAKE) home DRY_RUN=1

dry-run-vm: ## Like 'vm' in Ansible check mode
	@$(MAKE) vm DRY_RUN=1

# ---- Auxiliary targets (host) ----------------------------------------

# Partial targets pass a single tag so Ansible does not OR-match the umbrella `home`/`vm` tag
# (which would run every role in the profile).

fonts-home: setup ## Install Nerd Fonts on the host (~/.local/share/fonts)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=home --tags fonts-home

packages-home: setup ## Install Arch packages with pacman on the host
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=home --tags packages-home $(HOME_BECOME)

flatpaks: setup ## Configure user Flathub and install Flatpak apps
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=home --tags flatpaks $(FLATPAK_BECOME)

distrobox: setup ## Install local distrobox and create the 'fedora' container
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=home --tags distrobox

# Same heuristic as roles/common for Distrobox/podman user containers.
# Override: PYTHON_USER_TOOLS_PROFILE=home|vm make python-user-tools
python-user-tools: setup ## pip --user + stown (profile home vs vm chosen automatically)
	@profile="$$PYTHON_USER_TOOLS_PROFILE"; \
	if [ -z "$$profile" ]; then \
		profile=home; \
		if [ -f /run/.containerenv ] || [ -d /run/host ] || [ -n "$$DISTROBOX_ENTER_PATH" ] || [ -n "$$CONTAINER_ID" ]; then profile=vm; fi; \
	fi; \
	"$(ANSIBLE_PLAYBOOK)" -i $(INV) playbook.yml -e dotfiles_profile="$$profile" --tags python-user-tools

stown-home: setup ## Apply home-profile dotfiles with stown
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=home --tags stown-home

language-home: languages-home

languages-home: setup ## Install fnm/uv/pnpm into ~/.local on the host
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=home --tags languages-home

starship-home: setup ## Install starship (prompt) into ~/.local/bin on the host
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=home --tags starship-home

shell-plugins-home: setup ## Install oh-my-zsh + plugins on the host
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=home --tags shell-plugins-home

# ---- Auxiliary targets (vm) ------------------------------------------

fonts-vm: setup ## Install Nerd Fonts inside the container (~/.local/share/fonts)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=vm --tags fonts-vm

packages-vm: setup ## Install Fedora packages with dnf inside the container
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=vm --tags packages-vm

vscode-insiders: setup ## Install VS Code Insiders inside the container
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=vm --tags vscode-insiders

podman-compose: setup ## Install podman-compose into ~/.local/bin (container)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=vm --tags podman-compose

starship-vm: setup ## Install starship (prompt) into ~/.local/bin (container)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=vm --tags starship-vm

languages-vm: setup ## Install Go/fnm/Julia/JDK/uv/Gradle/pnpm into ~/.local (container)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=vm --tags languages-vm

shell-plugins-vm: setup ## Install oh-my-zsh + plugins (container)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=vm --tags shell-plugins-vm

stown-vm: setup ## Apply vm-profile dotfiles with stown
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=vm --tags stown-vm
