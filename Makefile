SHELL := /bin/bash
.DEFAULT_GOAL := setup

PACKAGES := git shell-container starship nvim-vm ghostty niri waybar mako rofi
SCRIPT_FILES := bootstrap-dotfiles.sh $(wildcard scripts/*.sh) \
	$(wildcard packages/rofi/.config/rofi/scripts/*) \
	$(wildcard packages/waybar/.config/waybar/scripts/*)

.PHONY: help setup fonts dotfiles stow check doctor verify

help: ## List available targets
	@awk 'BEGIN {FS = ":.*?## "}; /^[a-zA-Z_-]+:.*?## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

setup: ## Install fonts, link dotfiles, and run static checks
	@$(MAKE) --no-print-directory fonts
	@$(MAKE) --no-print-directory dotfiles
	@$(MAKE) --no-print-directory check

fonts: scripts/install-fonts.sh ## Install the configured user-local fonts
	@./scripts/install-fonts.sh

dotfiles: ## Link every dotfile package with the existing GNU Stow
	@./scripts/apply-dotfiles.sh $(PACKAGES)

stow: dotfiles ## Alias for dotfiles

check: ## Run non-mutating repository syntax checks
	@for file in $(SCRIPT_FILES) packages/shell-container/.bashrc packages/shell-container/.profile; do bash -n "$$file"; done
	@if command -v zsh >/dev/null 2>&1; then zsh -n packages/shell-container/.zshrc; fi
	@python3 -m json.tool packages/waybar/.config/waybar/config.jsonc >/dev/null
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck $(SCRIPT_FILES); fi
	@echo "check: OK"

doctor: ## Validate required commands, configs, and managed links on this machine
	@./scripts/doctor.sh $(PACKAGES)

verify: check doctor ## Run static and machine-specific validation
