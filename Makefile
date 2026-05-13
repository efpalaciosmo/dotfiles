SHELL := /usr/bin/env bash

VENV := $(CURDIR)/.venv
PIP := $(VENV)/bin/pip
ANSIBLE_PLAYBOOK := $(VENV)/bin/ansible-playbook
ANSIBLE_GALAXY := $(VENV)/bin/ansible-galaxy
INV := $(CURDIR)/inventory.ini
# Pass DRY_RUN=1 with --check for dry-run (see README).
CHECK := $(if $(filter 1,$(DRY_RUN)),--check,)
# Flatpak only needs sudo when a system Flathub remote exists and should be removed.
FLATPAK_BECOME = $(shell flatpak remotes --system 2>/dev/null | awk '$$1 == "flathub" { print "--ask-become-pass"; exit }')

.PHONY: help setup doctor check verify \
        aeon tw-vm arch home vm \
        dry-run-aeon dry-run-tw-vm dry-run-arch dry-run-home dry-run-vm \
        fonts-aeon flatpaks stown-aeon \
        python-user-tools starship-aeon language-aeon languages-aeon shell-plugins-aeon \
        fonts-tw-vm packages-tw-vm vscode-insiders podman-compose \
        starship-tw-vm languages-tw-vm shell-plugins-tw-vm stown-tw-vm \
        packages-arch fonts-arch starship-arch languages-arch language-arch \
        shell-plugins-arch stown-arch

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

doctor: setup ## Show local command and dotfile diagnostics
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook-doctor.yml

check: setup ## Ansible syntax-check (+ ansible-lint if installed)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=aeon --syntax-check
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=tw-vm --syntax-check
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=arch --syntax-check
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook-doctor.yml --syntax-check
	@command -v ansible-lint >/dev/null 2>&1 && ansible-lint -q . || true

# Partial Makefile targets must not pass `--tags foo,aeon` / `foo,tw-vm` /
# `foo,arch` (Ansible OR would run the whole profile).
verify: check
	@! grep -E 'playbook\.yml.*--tags [^ ]+,(aeon|tw-vm|arch)' $(MAKEFILE_LIST) \
		|| (echo >&2 "verify: drop umbrella ,aeon/,tw-vm/,arch from partial playbook invocations"; exit 1)
	@echo "verify: OK"

# ---- Main profiles ---------------------------------------------------

aeon: setup ## Configure the openSUSE Aeon host user-space profile
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=aeon --tags aeon $(FLATPAK_BECOME) $(CHECK)

tw-vm: setup ## Configure the manually entered Tumbleweed Distrobox profile
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=tw-vm --tags tw-vm $(CHECK)

# Arch installs system packages with `sudo pacman -S`, so we always pass
# --ask-become-pass. Override BECOME_FLAGS to "" if your sudoers allows
# passwordless sudo for pacman / systemctl / usermod.
ARCH_BECOME ?= --ask-become-pass
arch: setup ## Configure the Arch Linux host profile (installs pacman packages)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=arch --tags arch $(ARCH_BECOME) $(CHECK)

home: aeon ## Compatibility alias for aeon

vm: tw-vm ## Compatibility alias for tw-vm

# ---- Dry-run mode ----------------------------------------------------

dry-run-aeon: ## Like 'aeon' in Ansible check mode
	@$(MAKE) aeon DRY_RUN=1

dry-run-tw-vm: ## Like 'tw-vm' in Ansible check mode
	@$(MAKE) tw-vm DRY_RUN=1

dry-run-arch: ## Like 'arch' in Ansible check mode (no sudo prompt)
	@$(MAKE) arch DRY_RUN=1 ARCH_BECOME=

dry-run-home: dry-run-aeon ## Compatibility alias for dry-run-aeon

dry-run-vm: dry-run-tw-vm ## Compatibility alias for dry-run-tw-vm

# ---- Auxiliary targets (Aeon host) -----------------------------------

# Partial targets pass a single tag so Ansible does not OR-match the umbrella
# `aeon`/`tw-vm` tag, which would run every role in the profile.

fonts-aeon: setup ## Install Nerd Fonts on the host (~/.local/share/fonts)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=aeon --tags fonts-aeon

flatpaks: setup ## Configure user Flathub and install Flatpak apps
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=aeon --tags flatpaks $(FLATPAK_BECOME)

# Override: PYTHON_USER_TOOLS_PROFILE=aeon|tw-vm|arch make python-user-tools
python-user-tools: setup ## pip --user + stown for the selected profile (default: aeon)
	@profile="$${PYTHON_USER_TOOLS_PROFILE:-aeon}"; \
	case "$$profile" in aeon|tw-vm|arch) ;; *) echo >&2 "PYTHON_USER_TOOLS_PROFILE must be aeon, tw-vm, or arch"; exit 1;; esac; \
	"$(ANSIBLE_PLAYBOOK)" -i $(INV) playbook.yml -e dotfiles_profile="$$profile" --tags python-user-tools

stown-aeon: setup ## Apply Aeon-profile dotfiles with stown
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=aeon --tags stown-aeon

language-aeon: languages-aeon

languages-aeon: setup ## Install fnm/uv/pnpm into ~/.local on the host
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=aeon --tags languages-aeon

starship-aeon: setup ## Install starship (prompt) into ~/.local/bin on the host
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=aeon --tags starship-aeon

shell-plugins-aeon: setup ## Install oh-my-zsh + plugins on the host
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=aeon --tags shell-plugins-aeon

# ---- Auxiliary targets (Tumbleweed VM) -------------------------------

fonts-tw-vm: setup ## Install Nerd Fonts inside the container (~/.local/share/fonts)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=tw-vm --tags fonts-tw-vm

packages-tw-vm: setup ## Install Tumbleweed packages with zypper inside the container
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=tw-vm --tags packages-tw-vm

vscode-insiders: setup ## Install VS Code Insiders inside the container
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=tw-vm --tags vscode-insiders

podman-compose: setup ## Install podman-compose into ~/.local/bin (container)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=tw-vm --tags podman-compose

starship-tw-vm: setup ## Install starship (prompt) into ~/.local/bin (container)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=tw-vm --tags starship-tw-vm

languages-tw-vm: setup ## Install Go/fnm/Julia/JDK/uv/Gradle/pnpm into ~/.local (container)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=tw-vm --tags languages-tw-vm

shell-plugins-tw-vm: setup ## Install oh-my-zsh + plugins (container)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=tw-vm --tags shell-plugins-tw-vm

stown-tw-vm: setup ## Apply tw-vm-profile dotfiles with stown
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=tw-vm --tags stown-tw-vm

# ---- Auxiliary targets (Arch host) -----------------------------------

packages-arch: setup ## Install Arch packages with pacman (sudo required)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=arch --tags packages-arch $(ARCH_BECOME)

fonts-arch: setup ## Install Nerd Fonts on the Arch host (~/.local/share/fonts)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=arch --tags fonts-arch

starship-arch: setup ## Install starship (prompt) into ~/.local/bin (Arch host)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=arch --tags starship-arch

language-arch: languages-arch

languages-arch: setup ## Install fnm/uv/pnpm into ~/.local on the Arch host
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=arch --tags languages-arch

shell-plugins-arch: setup ## Install oh-my-zsh + plugins on the Arch host
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=arch --tags shell-plugins-arch

stown-arch: setup ## Apply Arch-profile dotfiles with stown
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=arch --tags stown-arch
