SHELL := /bin/sh
.DEFAULT_GOAL := setup
# The tiny launcher runs under Apple's Bash 3.2 and selects Bash 5+ on Darwin.
BASH_RUN := /bin/bash "$(CURDIR)/scripts/bash.sh"

.PHONY: help setup doctor check verify test
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*## ' Makefile | awk 'BEGIN {FS = ":.*## "}; {printf "  %-18s %s\n", $$1, $$2}'

setup: check ## Install all software and apply selected macOS preferences
	@$(BASH_RUN) scripts/setup.sh setup
	@if [ "$(DRY_RUN)" != 1 ]; then $(MAKE) verify && $(MAKE) doctor; fi

doctor: ## Validate installed software, runtimes and macOS preferences
	@$(BASH_RUN) scripts/setup.sh doctor

check: ## Check Bash syntax and run ShellCheck when available
	@$(BASH_RUN) scripts/check.sh

verify: check ## Syntax/lint and regression tests (no installation)
	@$(BASH_RUN) tests/setup-test.sh

test: verify ## Run offline installer and macOS preference regression tests
