SHELL := /usr/bin/env zsh

VENV := $(CURDIR)/.venv
PIP := $(VENV)/bin/pip
ANSIBLE_PLAYBOOK := $(VENV)/bin/ansible-playbook
ANSIBLE_GALAXY := $(VENV)/bin/ansible-galaxy
INV := $(CURDIR)/inventory.ini
# Pass DRY_RUN=1 with --check for dry-run (see README).
CHECK := $(if $(filter 1,$(DRY_RUN)),--check,)

.PHONY: help setup doctor check verify \
        suse dry-run-suse audit-suse \
        python-user-tools \
        packages-suse desktop-suse fonts-suse vscode-insiders podman-compose \
        starship-suse languages-suse shell-plugins-suse stown-suse

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-22s %s\n", $$1, $$2}'

setup: ## Create .venv, install ansible-core + collections, ensure inventory.ini
	@command -v python3 >/dev/null 2>&1 \
		|| { echo >&2 "[setup] python3 not found. On openSUSE: sudo zypper install python3."; exit 1; }
	@if [ ! -x "$(ANSIBLE_PLAYBOOK)" ] \
		|| ! "$(ANSIBLE_PLAYBOOK)" --version >/dev/null 2>&1 \
		|| ! "$(ANSIBLE_GALAXY)" --version >/dev/null 2>&1; then \
		echo "[setup] (re)creating $(VENV) for $$(python3 -c 'import sys,platform;print(sys.executable, platform.platform())')"; \
		rm -rf "$(VENV)"; \
		python3 -m venv "$(VENV)"; \
		"$(PIP)" install --upgrade pip >/dev/null; \
		"$(PIP)" install -r requirements-ansible.txt; \
	fi
	@mkdir -p "$(CURDIR)/.ansible/collections"
	@"$(ANSIBLE_GALAXY)" collection install -r requirements.yml -p "$(CURDIR)/.ansible/collections"
	@test -f "$(INV)" || cp inventory.ini.example "$(INV)"

# ---- Validation ------------------------------------------------------

doctor: setup ## Show local command and dotfile diagnostics
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook-doctor.yml

check: setup ## Ansible syntax-check (+ ansible-lint if installed)
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --syntax-check
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook-doctor.yml --syntax-check
	@command -v ansible-lint >/dev/null 2>&1 && ansible-lint -q . || true

# Partial Makefile targets must not pass `--tags foo,suse`
# (Ansible OR would run the whole profile).
verify: check
	@! grep -E 'playbook\.yml.*--tags [^ ]+,suse' $(MAKEFILE_LIST) \
		|| (echo >&2 "verify: drop umbrella ,suse from partial playbook invocations"; exit 1)
	@old='tw''-vm|packages-''arch|dry-run-''arch|nvim-''arch|shell-''arch|stown_packages_''arch|stown_packages_''tw_vm|arch_pac''man_''packages|dotfiles_profile=''arch|dotfiles_profile=tw''-vm|pac''man'; \
		! grep -R -n -I -E "$$old" Makefile playbook.yml bootstrap-dotfiles.sh tasks roles group_vars packages README.md \
		|| (echo >&2 "verify: old profile residue found"; exit 1)
	@echo "verify: OK"

# ---- Main profile ----------------------------------------------------

suse: setup ## Configure the openSUSE profile
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --tags suse $(CHECK)

dry-run-suse: ## Like 'suse' in Ansible check mode
	@$(MAKE) suse DRY_RUN=1

audit-suse: ## Report versions and package metadata inside distrobox 'suse'
	@command -v distrobox >/dev/null 2>&1 \
		|| { echo >&2 "audit-suse: distrobox not found on PATH"; exit 127; }
	@distrobox enter suse -- sh -lc '\
		set -eu; \
		printf "== OS ==\n"; . /etc/os-release; printf "%s %s\n" "$$NAME" "$${VERSION_ID:-}"; \
		printf "\n== Tool versions ==\n"; \
		for cmd in niri waybar xwayland-satellite foot mako rofi wl-copy wl-paste cliphist pactl wireplumber; do \
			if command -v "$$cmd" >/dev/null 2>&1; then \
				printf "%-20s " "$$cmd"; "$$cmd" --version 2>&1 | head -n 1 || true; \
			else \
				printf "%-20s MISSING\n" "$$cmd"; \
			fi; \
		done; \
		printf "\n== Package metadata ==\n"; \
		zypper --no-refresh info niri waybar mako rofi-wayland foot cliphist xwayland-satellite pulseaudio-utils pipewire pipewire-pulseaudio wireplumber wl-clipboard grim slurp swappy pavucontrol libnotify-tools NetworkManager-gnome bluez playerctl brightnessctl \
	'

# ---- Auxiliary targets ----------------------------------------------

python-user-tools: setup ## pip --user + stown
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --tags python-user-tools

packages-suse: setup ## Install openSUSE packages with zypper
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --tags packages-suse

desktop-suse: setup ## Enable desktop services and create desktop dirs
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --tags desktop-suse

fonts-suse: setup ## Install Nerd Fonts into ~/.local/share/fonts
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --tags fonts-suse

vscode-insiders: setup ## Install VS Code Insiders from the Microsoft RPM repo
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --tags vscode-insiders

podman-compose: setup ## Install podman-compose into ~/.local/bin
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --tags podman-compose

starship-suse: setup ## Install starship into ~/.local/bin
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --tags starship-suse

languages-suse: setup ## Install Go/fnm/Julia/JDK/uv/Gradle/pnpm into ~/.local
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --tags languages-suse

shell-plugins-suse: setup ## Install oh-my-zsh + plugins
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --tags shell-plugins-suse

stown-suse: setup ## Apply suse-profile dotfiles with stown
	@$(ANSIBLE_PLAYBOOK) -i $(INV) playbook.yml -e dotfiles_profile=suse --tags stown-suse
