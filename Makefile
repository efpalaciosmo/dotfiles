SHELL := /bin/bash
.DEFAULT_GOAL := setup

PACKAGES := git shell-container vi kitty niri waybar mako rofi
SCRIPT_FILES := bootstrap-dotfiles.sh $(wildcard scripts/*.sh) \
	$(filter-out packages/rofi/.config/rofi/scripts/clipboard-history packages/rofi/.config/rofi/scripts/wifi,$(wildcard packages/rofi/.config/rofi/scripts/*)) \
	$(wildcard packages/waybar/.config/waybar/scripts/*)
PYTHON_FILES := packages/rofi/.config/rofi/scripts/clipboard-history packages/rofi/.config/rofi/scripts/wifi

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
	@for file in $(SCRIPT_FILES) packages/shell-container/.bashrc packages/shell-container/.profile; do bash -n "$$file" || exit 1; done
	@python3 -m json.tool packages/waybar/.config/waybar/config.jsonc >/dev/null
	@python3 -c 'import ast, pathlib; [ast.parse(pathlib.Path(p).read_text()) for p in "$(PYTHON_FILES)".split()]'
	@if command -v vi >/dev/null 2>&1; then \
		output=$$(mktemp); \
		vi -Nu packages/vi/.virc --not-a-term -n -c "redir! > $$output" -c 'set number? relativenumber? shiftwidth?' -c 'redir END' -c 'qa!' </dev/null >/dev/null 2>&1 && \
		grep -Eq '^[[:space:]]*number[[:space:]]*$$' "$$output" && \
		grep -Eq '^[[:space:]]*relativenumber[[:space:]]*$$' "$$output" && \
		grep -q 'shiftwidth=4' "$$output"; result=$$?; \
		rm -f -- "$$output"; exit $$result; \
	fi
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck -x -P packages/rofi/.config/rofi/scripts $(SCRIPT_FILES); fi
	@echo "check: OK"

doctor: ## Validate required commands, configs, and managed links on this machine
	@./scripts/doctor.sh $(PACKAGES)

verify: check doctor ## Run static and machine-specific validation
