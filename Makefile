SHELL := /bin/bash
.DEFAULT_GOAL := help

ANSIBLE_VENV ?= $(if $(XDG_DATA_HOME),$(XDG_DATA_HOME),$(HOME)/.local/share)/dotfiles/ansible-venv
ANSIBLE_PLAYBOOK = $(ANSIBLE_VENV)/bin/ansible-playbook
TEST_PYTHON = $(if $(wildcard $(ANSIBLE_VENV)/bin/python),$(ANSIBLE_VENV)/bin/python,python3)

PACKAGES := git shell-container starship vi kitty niri waybar mako fuzzel
SCRIPT_FILES := bootstrap-dotfiles.sh $(wildcard scripts/*.sh) \
	$(wildcard packages/niri/.config/niri/scripts/*) \
	$(filter-out packages/fuzzel/.config/fuzzel/scripts/clipboard-history packages/fuzzel/.config/fuzzel/scripts/wifi packages/fuzzel/.config/fuzzel/scripts/picker,$(shell find packages/fuzzel/.config/fuzzel/scripts -maxdepth 1 -type f)) \
	$(wildcard packages/waybar/.config/waybar/scripts/*)
PYTHON_FILES := packages/fuzzel/.config/fuzzel/scripts/clipboard-history packages/fuzzel/.config/fuzzel/scripts/wifi packages/fuzzel/.config/fuzzel/scripts/picker

.PHONY: help setup local packages fonts dotfiles stow flatpak check doctor verify

help: ## List available targets
	@awk 'BEGIN {FS = ":.*?## "}; /^[a-zA-Z_-]+:.*?## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

setup: ## Run the full Ansible playbook (CachyOS only)
	@ANSIBLE_VENV="$(ANSIBLE_VENV)" bash scripts/ensure-ansible.sh system
	@sudo -v
	@"$(ANSIBLE_PLAYBOOK)" -i localhost, setup.yml

local: ## Run Ansible fonts, dotfiles and checks without system packages
	@ANSIBLE_VENV="$(ANSIBLE_VENV)" bash scripts/ensure-ansible.sh
	@"$(ANSIBLE_PLAYBOOK)" -i localhost, setup.yml --tags local

packages: ## Run Ansible package installation (CachyOS only)
	@ANSIBLE_VENV="$(ANSIBLE_VENV)" bash scripts/ensure-ansible.sh system
	@sudo -v
	@"$(ANSIBLE_PLAYBOOK)" -i localhost, setup.yml --tags packages

fonts: ## Install the configured user-local fonts with Ansible
	@ANSIBLE_VENV="$(ANSIBLE_VENV)" bash scripts/ensure-ansible.sh
	@"$(ANSIBLE_PLAYBOOK)" -i localhost, setup.yml --tags fonts

dotfiles: ## Link every dotfile package with Ansible and GNU Stow
	@ANSIBLE_VENV="$(ANSIBLE_VENV)" bash scripts/ensure-ansible.sh
	@"$(ANSIBLE_PLAYBOOK)" -i localhost, setup.yml --tags dotfiles

stow: dotfiles ## Alias for dotfiles

flatpak: ## Install Flathub apps for this user (not part of setup)
	@ANSIBLE_VENV="$(ANSIBLE_VENV)" bash scripts/ensure-ansible.sh
	@"$(ANSIBLE_PLAYBOOK)" -i localhost, flatpak.yml

check: ## Run non-mutating repository syntax checks
	@for file in $(SCRIPT_FILES) packages/shell-container/.bashrc packages/shell-container/.profile packages/shell-container/.local/bin/fedora-terminal; do bash -n "$$file" || exit 1; done
	@if command -v zsh >/dev/null 2>&1; then zsh -n packages/shell-container/.zshrc; fi
	@python3 -c 'import pathlib, tomllib; tomllib.loads(pathlib.Path("packages/starship/.config/starship.toml").read_text())'
	@python3 -m json.tool packages/waybar/.config/waybar/config.jsonc >/dev/null
	@python3 -c 'import ast, pathlib; [ast.parse(pathlib.Path(p).read_text()) for p in "$(PYTHON_FILES)".split()]'
	@PYTHONDONTWRITEBYTECODE=1 "$(TEST_PYTHON)" -m unittest discover -s tests -p 'test_*.py'
	@if command -v niri >/dev/null 2>&1; then niri validate --config packages/niri/.config/niri/config.kdl; fi
	@if command -v fuzzel >/dev/null 2>&1; then fuzzel --check-config --config=packages/fuzzel/.config/fuzzel/fuzzel.ini; fi
	@if command -v vim >/dev/null 2>&1; then \
		output=$$(mktemp); \
		vim -Nu packages/vi/.vimrc --not-a-term -n -c "redir! > $$output" -c 'set number? relativenumber? shiftwidth?' -c 'redir END' -c 'qa!' </dev/null >/dev/null 2>&1 && \
		grep -Eq '^[[:space:]]*number[[:space:]]*$$' "$$output" && \
		grep -Eq '^[[:space:]]*relativenumber[[:space:]]*$$' "$$output" && \
		grep -q 'shiftwidth=4' "$$output"; result=$$?; \
		rm -f -- "$$output"; exit $$result; \
	fi
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck -x -P packages/fuzzel/.config/fuzzel/scripts $(SCRIPT_FILES); fi
	@echo "check: OK"

doctor: ## Validate required commands, configs, and managed links on this machine
	@./scripts/doctor.sh $(PACKAGES)

verify: check doctor ## Run static and machine-specific validation
