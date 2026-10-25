SHELL := /bin/bash
.DEFAULT_GOAL := setup
export DRY_RUN

.PHONY: help setup packages fonts fnm dotfiles stow doctor check verify test shell-check

help: ## List available targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: verify ## Install Fedora packages, tools, fonts and dotfiles, then validate
	@bash scripts/setup.sh setup
	@if [ "$(DRY_RUN)" != "1" ]; then $(MAKE) doctor; fi

packages: ## Install missing packages from Fedora repositories
	@bash scripts/setup.sh packages

fonts: ## Install pinned user-local fonts
	@bash scripts/setup.sh fonts

fnm: ## Install fnm, Node.js LTS and pnpm
	@bash scripts/setup.sh fnm

dotfiles: ## Back up conflicts and link dotfiles with GNU Stow
	@bash scripts/setup.sh dotfiles

stow: dotfiles ## Alias for make dotfiles

doctor: ## Validate commands, managed links and LaTeX resources
	@bash scripts/setup.sh doctor

check: ## Check Bash syntax and run ShellCheck when installed
	@bash -n packages/shell-container/.profile
	@bash -n packages/shell-container/.bashrc
	@if command -v zsh >/dev/null 2>&1; then zsh -n packages/shell-container/.zshrc; fi
	@bash -n bootstrap-dotfiles.sh
	@for script in scripts/*.sh tests/*.sh; do bash -n "$$script" || exit; done
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck -x bootstrap-dotfiles.sh packages/shell-container/.profile scripts/*.sh tests/*.sh; fi

shell-check: ## Test interactive Bash, zsh and Starship startup
	@bash scripts/check-shell.sh

test: check ## Run isolated Bash regression and shell startup tests
	@bash tests/setup-test.sh
	@bash scripts/check-shell.sh

verify: check ## Check syntax and guard against obsolete tooling
	@old='br''ew|st''own|an''sible'; \
		! grep -R -n -I -i -E "(^|[^[:alnum:]_-])($$old)([^[:alnum:]_-]|$$)" Makefile bootstrap-dotfiles.sh scripts packages README.md \
		|| { echo >&2 "verify: obsolete tooling reference found"; exit 1; }
	@echo "verify: OK"
