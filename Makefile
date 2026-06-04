SHELL := /bin/sh
.DEFAULT_GOAL := setup

VENV := $(CURDIR)/.venv
PIP := $(VENV)/bin/pip
ANSIBLE_PLAYBOOK := $(VENV)/bin/ansible-playbook
INV := $(CURDIR)/inventory.ini
CHECK := $(if $(filter 1,$(DRY_RUN)),--check,)
BREW_BUNDLE_JOBS ?= auto

.PHONY: help setup brew venv doctor check verify fonts shell dotfiles treesitter python-user-tools

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

setup: brew venv ## Bootstrap Homebrew, apply dotfiles, and validate
	@"$(CURDIR)/scripts/with-homebrew.sh" \
		"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook.yml $(CHECK)
	@$(MAKE) verify

brew: Brewfile scripts/ensure-homebrew.sh scripts/with-homebrew.sh ## Install Homebrew if needed and run brew bundle
	@if [ "$(DRY_RUN)" = "1" ]; then \
		"$(CURDIR)/scripts/with-homebrew.sh" --no-install env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file="$(CURDIR)/Brewfile"; \
	else \
		if ! command -v brew >/dev/null 2>&1 && [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then \
			echo "[brew] Preparing Homebrew prefix with root privileges..."; \
			sudo install -d -m 0755 -o "$$(id -u)" -g "$$(id -g)" /home/linuxbrew; \
			sudo install -d -m 0755 -o "$$(id -u)" -g "$$(id -g)" /home/linuxbrew/.linuxbrew; \
		fi; \
		"$(CURDIR)/scripts/with-homebrew.sh" brew bundle install --jobs="$(BREW_BUNDLE_JOBS)" --file="$(CURDIR)/Brewfile"; \
	fi

venv: requirements-ansible.txt ## Create the local Ansible virtualenv
	@brew_env=$$("$(CURDIR)/scripts/ensure-homebrew.sh" --no-install --shellenv 2>/dev/null || true); \
		eval "$$brew_env"; \
		command -v python3 >/dev/null 2>&1 \
			|| { echo >&2 "[venv] python3 not found. Run 'make brew' first or install Python with Homebrew."; exit 1; }; \
		if [ ! -x "$(ANSIBLE_PLAYBOOK)" ] \
			|| ! "$(ANSIBLE_PLAYBOOK)" --version >/dev/null 2>&1; then \
			echo "[venv] (re)creating $(VENV)"; \
			rm -rf "$(VENV)"; \
			python3 -m venv "$(VENV)" \
				|| { echo >&2 "[venv] python3 venv support is missing or broken."; exit 1; }; \
			"$(PIP)" install --upgrade pip >/dev/null; \
			"$(PIP)" install -r requirements-ansible.txt; \
		fi
	@mkdir -p "$(CURDIR)/.ansible/tmp"
	@test -f "$(INV)" || cp inventory.ini.example "$(INV)"

doctor: venv ## Show Homebrew, command, and dotfile diagnostics
	@brew_env=$$("$(CURDIR)/scripts/ensure-homebrew.sh" --no-install --shellenv 2>/dev/null || true); \
		eval "$$brew_env"; \
		"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook-doctor.yml

check: venv ## Ansible syntax-check (+ ansible-lint if installed)
	@brew_env=$$("$(CURDIR)/scripts/ensure-homebrew.sh" --no-install --shellenv 2>/dev/null || true); \
		eval "$$brew_env"; \
		"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook.yml --syntax-check; \
		"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook-doctor.yml --syntax-check; \
		command -v ansible-lint >/dev/null 2>&1 && ansible-lint -q . || true

verify: check ## Check syntax and guard against distro package-manager residue
	@old='zyp''per|open''su''se|su''se|d''nf|a''pt|pac''man|rpm-ost''ree'; \
		files='Makefile Brewfile playbook.yml playbook-doctor.yml bootstrap-dotfiles.sh scripts tasks roles group_vars packages README.md'; \
		! grep -R -n -I -i -E "(^|[^[:alnum:]_-])($$old)([^[:alnum:]_-]|$$)" $$files \
		|| (echo >&2 "verify: distro package-manager residue found"; exit 1)
	@for dir in ni''ri way''bar ma''ko ro''fi fo''ot; do \
		test ! -d "packages/$$dir" || exit 1; \
	done
	@echo "verify: OK"

fonts: brew venv ## Install user-local fonts
	@"$(CURDIR)/scripts/with-homebrew.sh" \
		"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook.yml --tags fonts $(CHECK)

shell: brew venv ## Install oh-my-zsh and shell plugins
	@"$(CURDIR)/scripts/with-homebrew.sh" \
		"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook.yml --tags shell $(CHECK)

dotfiles: brew venv ## Install stown if needed and apply dotfiles
	@"$(CURDIR)/scripts/with-homebrew.sh" \
		"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook.yml --tags python-user-tools,dotfiles $(CHECK)

treesitter: brew venv ## Install Neovim Tree-sitter parsers
	@"$(CURDIR)/scripts/with-homebrew.sh" \
		"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook.yml --tags nvim-treesitter $(CHECK)

python-user-tools: brew venv
	@"$(CURDIR)/scripts/with-homebrew.sh" \
		"$(ANSIBLE_PLAYBOOK)" -i "$(INV)" playbook.yml --tags python-user-tools $(CHECK)
