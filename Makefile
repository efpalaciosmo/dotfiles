SHELL := /bin/bash
.DEFAULT_GOAL := all

TEST_PYTHON ?= python3

PACKAGES := git shell-container starship vi ghostty niri waybar mako fuzzel desktop
SCRIPT_FILES := bootstrap-dotfiles.sh $(wildcard scripts/*.sh) \
	$(wildcard packages/niri/.config/niri/scripts/*) \
	packages/desktop/.local/bin/dotfiles-appearance \
	$(filter-out packages/fuzzel/.config/fuzzel/scripts/clipboard-history packages/fuzzel/.config/fuzzel/scripts/wifi packages/fuzzel/.config/fuzzel/scripts/picker,$(shell find packages/fuzzel/.config/fuzzel/scripts -maxdepth 1 -type f)) \
	$(wildcard packages/waybar/.config/waybar/scripts/*)
PYTHON_FILES := $(wildcard scripts/*.py) $(wildcard cachyos/config/*.py) packages/fuzzel/.config/fuzzel/scripts/clipboard-history packages/fuzzel/.config/fuzzel/scripts/wifi packages/fuzzel/.config/fuzzel/scripts/picker

.PHONY: all help setup local dotfiles stow check doctor verify system-check cachyos-plan

# Keep installation and linking sequential even with make -j.
all: setup ## Install packages, enable services, then synchronize all dotfiles
	@$(MAKE) --no-print-directory dotfiles

help: ## List available targets
	@awk 'BEGIN {FS = ":.*?## "}; /^[a-zA-Z_-]+:.*?## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

setup: ## Install CachyOS packages and system configuration; enable services for next boot
	@bash scripts/setup.sh

local: check ## Validate and link personal dotfiles only (no package installation)
	@$(MAKE) --no-print-directory dotfiles

dotfiles: ## Link selected dotfile packages with GNU Stow and back up conflicts
	@bash scripts/apply-dotfiles.sh $(PACKAGES)

stow: dotfiles ## Alias for dotfiles

check: ## Run non-mutating repository syntax checks
	@for file in $(SCRIPT_FILES) packages/shell-container/.bashrc packages/shell-container/.profile packages/shell-container/.local/bin/fedora-terminal; do bash -n "$$file" || exit 1; done
	@if command -v zsh >/dev/null 2>&1; then zsh -n packages/shell-container/.zshrc; fi
	@python3 -c 'import pathlib, tomllib; tomllib.loads(pathlib.Path("packages/starship/.config/starship.toml").read_text())'
	@python3 -m json.tool packages/waybar/.config/waybar/config.jsonc >/dev/null
	@python3 -m json.tool cachyos/modules.json >/dev/null
	@python3 -c 'import ast, pathlib; [ast.parse(pathlib.Path(p).read_text()) for p in "$(PYTHON_FILES)".split()]'
	@PYTHONDONTWRITEBYTECODE=1 "$(TEST_PYTHON)" -m unittest discover -s tests -p 'test_*.py'
	@if command -v niri >/dev/null 2>&1; then niri validate --config packages/niri/.config/niri/config.kdl; fi
	@if command -v niri >/dev/null 2>&1; then niri validate --config cachyos/config/niri.kdl; fi
	@if command -v fuzzel >/dev/null 2>&1; then fuzzel --check-config --log-no-syslog --config=packages/fuzzel/.config/fuzzel/fuzzel.ini; fi
	@if command -v ghostty >/dev/null 2>&1; then bash scripts/validate-configs.sh ghostty; fi
	@if command -v desktop-file-validate >/dev/null 2>&1; then desktop-file-validate packages/desktop/.local/share/applications/*.desktop; fi
	@if command -v vim >/dev/null 2>&1; then \
		output=$$(mktemp); \
		vim -Nu packages/vi/.vimrc -i NONE -es -n -c "redir! > $$output" -c 'set number? relativenumber? shiftwidth?' -c 'redir END' -c 'qa!' </dev/null >/dev/null 2>&1 && \
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

system-check: ## Audit installed CachyOS packages, permissions and active services after reboot (sudo, read-only)
	@sudo python3 scripts/cachyos.py check --runtime

cachyos-plan: ## Preview the fixed CachyOS workstation installation (no changes)
	@python3 scripts/cachyos.py plan
