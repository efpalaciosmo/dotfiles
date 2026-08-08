SHELL := /bin/sh
.DEFAULT_GOAL := setup

VENV := $(CURDIR)/.venv
PIP := $(VENV)/bin/pip
ANSIBLE_PLAYBOOK := $(VENV)/bin/ansible-playbook
VENV_STAMP := $(VENV)/.requirements-installed
INV := $(CURDIR)/inventory.ini
CHECK := $(if $(filter 1,$(DRY_RUN)),--check,)
ASK_BECOME_PASS ?= 1
BECOME := $(if $(filter 1,$(DRY_RUN)),,$(if $(filter 1,$(ASK_BECOME_PASS)),--ask-become-pass,))

.PHONY: help setup venv packages fonts fnm dotfiles stow doctor check verify

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

setup: venv ## Install Fedora packages, apply dotfiles, and validate
	@"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" $(BECOME) playbook.yml $(CHECK)
	@$(MAKE) verify
	@if [ "$(DRY_RUN)" != "1" ]; then $(MAKE) doctor; fi

venv: $(VENV_STAMP) ## Create the local Ansible virtualenv
	@mkdir -p "$(CURDIR)/.ansible/tmp"
	@test -f "$(INV)" || cp inventory.ini.example "$(INV)"

$(VENV_STAMP): requirements-ansible.txt
	@command -v python3 >/dev/null 2>&1 \
		|| { echo >&2 "[venv] python3 is required; run bootstrap-dotfiles.sh first."; exit 1; }
	@if [ ! -x "$(ANSIBLE_PLAYBOOK)" ]; then \
		echo "[venv] creating $(VENV)"; \
		rm -rf "$(VENV)"; \
		python3 -m venv "$(VENV)"; \
	fi
	@"$(PIP)" install --upgrade pip >/dev/null
	@"$(PIP)" install -r requirements-ansible.txt
	@touch "$(VENV_STAMP)"

packages: venv ## Install packages from Fedora repositories with DNF5
	@"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" $(BECOME) playbook.yml --tags packages $(CHECK)

fonts: venv ## Install user-local fonts
	@"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook.yml --tags fonts $(CHECK)

fnm: venv ## Install fnm and the configured Node.js LTS release
	@"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook.yml --tags fnm $(CHECK)

dotfiles: venv ## Apply dotfiles with the preinstalled GNU Stow
	@"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook.yml --tags dotfiles $(CHECK)

stow: dotfiles ## Alias for make dotfiles

doctor: venv ## Show command and dotfile diagnostics
	@"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook-doctor.yml

check: venv ## Ansible syntax-check (+ ansible-lint if installed)
	@set -e; \
		"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook.yml --syntax-check; \
		"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook-doctor.yml --syntax-check; \
		if command -v ansible-lint >/dev/null 2>&1; then ansible-lint -q .; fi

verify: check ## Check syntax and guard against obsolete tooling
	@old='br''ew|st''own|ru''st|ca''rgo'; \
		files='Makefile playbook.yml playbook-doctor.yml bootstrap-dotfiles.sh tasks roles group_vars packages README.md'; \
		! grep -R -n -I -i -E "(^|[^[:alnum:]_-])($$old)([^[:alnum:]_-]|$$)" $$files \
		|| (echo >&2 "verify: obsolete tooling reference found"; exit 1)
	@echo "verify: OK"
