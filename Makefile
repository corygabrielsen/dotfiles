###############################################################################
# DOTFILES
###############################################################################
#
# Declarative dotfiles management via symlinks.
#
# USAGE:
#   make              Run setup (default target)
#   make setup        Complete environment setup
#   make require      Validate environment (read-only)
#   make doctor       Diagnose and troubleshoot
#
# BOOTSTRAP (fresh machine):
#   apt-get update && apt-get install -y make git
#   git clone git@github.com:corygabrielsen/dotfiles.git ~/code/dotfiles
#   cd ~/code/dotfiles && make
#
###############################################################################

SHELL := /bin/bash
.DEFAULT_GOAL := setup

# Repository root (where this Makefile lives)
DOTFILES := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# Colors
_COLOR_RESET := \033[0m
_COLOR_SUCCESS := \033[0;32m
_COLOR_ERROR := \033[0;31m
_COLOR_WARN := \033[0;33m
_COLOR_CMD := \033[0;94m
_COLOR_DIM := \033[0;90m
_COLOR_BOLD := \033[1m

###############################################################################
# SYMLINK DEFINITIONS
###############################################################################
# Format: target:source (relative to DOTFILES)
# target = ~/.{name}, source = {folder}/{name}

SYMLINKS := \
	gitconfig:git/gitconfig \
	git-template:git/git-template \
	tmux.conf:tmux/tmux.conf \
	vim:vim/vim \
	vimrc:vim/vimrc \
	zshenv:zsh/zshenv \
	zprofile:zsh/zprofile \
	zshrc:zsh/zshrc

###############################################################################
# TIER 1: ORCHESTRATORS
###############################################################################

.PHONY: setup
setup: install-symlinks install-git-config
	@printf '%b%s%b %s\n' '$(_COLOR_SUCCESS)' '✓' '$(_COLOR_RESET)' 'Setup complete'

.PHONY: require
require: require-symlinks
	@printf '%b%s%b %s\n' '$(_COLOR_SUCCESS)' '✓' '$(_COLOR_RESET)' 'Environment OK'

.PHONY: doctor
doctor: doctor-symlinks doctor-git-config
	@echo ""
	@printf '%b%s%b %s\n' '$(_COLOR_SUCCESS)' '✓' '$(_COLOR_RESET)' 'Doctor complete'

###############################################################################
# TIER 2: SYMLINKS
###############################################################################

.PHONY: install-symlinks
install-symlinks:
	@printf '%b%s%b\n' '$(_COLOR_BOLD)' 'symlinks' '$(_COLOR_RESET)'
	@$(foreach link,$(SYMLINKS),\
		$(eval target := $(HOME)/.$(word 1,$(subst :, ,$(link)))) \
		$(eval source := $(DOTFILES)/$(word 2,$(subst :, ,$(link)))) \
		if [ -L "$(target)" ] && [ "$$(readlink $(target))" = "$(source)" ]; then \
			printf '  %b%s%b %s\n' '$(_COLOR_SUCCESS)' '✓' '$(_COLOR_RESET)' '$(target)'; \
		else \
			rm -f "$(target)" 2>/dev/null || true; \
			ln -s "$(source)" "$(target)"; \
			printf '  %b%s%b %s -> %s\n' '$(_COLOR_SUCCESS)' '✓' '$(_COLOR_RESET)' '$(target)' '$(source)'; \
		fi;)

.PHONY: require-symlinks
require-symlinks:
	@$(foreach link,$(SYMLINKS),\
		$(eval target := $(HOME)/.$(word 1,$(subst :, ,$(link)))) \
		$(eval source := $(DOTFILES)/$(word 2,$(subst :, ,$(link)))) \
		if [ ! -L "$(target)" ] || [ "$$(readlink $(target))" != "$(source)" ]; then \
			printf '%b%s%b %s\n' '$(_COLOR_ERROR)' 'Error:' '$(_COLOR_RESET)' '$(target) not linked correctly'; \
			exit 1; \
		fi;)

.PHONY: doctor-symlinks
doctor-symlinks:
	@printf '%b%s%b\n' '$(_COLOR_BOLD)' 'symlinks' '$(_COLOR_RESET)'
	@$(foreach link,$(SYMLINKS),\
		$(eval target := $(HOME)/.$(word 1,$(subst :, ,$(link)))) \
		$(eval source := $(DOTFILES)/$(word 2,$(subst :, ,$(link)))) \
		if [ -L "$(target)" ] && [ "$$(readlink $(target))" = "$(source)" ]; then \
			printf '  %b%s%b %s\n' '$(_COLOR_SUCCESS)' '✓' '$(_COLOR_RESET)' '$(target)'; \
		elif [ -L "$(target)" ]; then \
			printf '  %b%s%b %s (wrong target: %s)\n' '$(_COLOR_WARN)' '!' '$(_COLOR_RESET)' '$(target)' "$$(readlink $(target))"; \
			printf '  %b%s%b\n' '$(_COLOR_DIM)' '  Fix: make install-symlinks' '$(_COLOR_RESET)'; \
		elif [ -e "$(target)" ]; then \
			printf '  %b%s%b %s (exists but not a symlink)\n' '$(_COLOR_WARN)' '!' '$(_COLOR_RESET)' '$(target)'; \
			printf '  %b%s%b\n' '$(_COLOR_DIM)' '  Fix: rm $(target) && make install-symlinks' '$(_COLOR_RESET)'; \
		else \
			printf '  %b%s%b %s (missing)\n' '$(_COLOR_ERROR)' '✗' '$(_COLOR_RESET)' '$(target)'; \
			printf '  %b%s%b\n' '$(_COLOR_DIM)' '  Fix: make install-symlinks' '$(_COLOR_RESET)'; \
		fi;)

###############################################################################
# TIER 2: GIT CONFIG
###############################################################################

.PHONY: install-git-config
install-git-config:
	@printf '%b%s%b\n' '$(_COLOR_BOLD)' 'git-config' '$(_COLOR_RESET)'
	@if git config user.email >/dev/null 2>&1; then \
		printf '  %b%s%b %s\n' '$(_COLOR_SUCCESS)' '✓' '$(_COLOR_RESET)' "user.email = $$(git config user.email)"; \
	else \
		printf '  %b%s%b\n' '$(_COLOR_WARN)' '!' '$(_COLOR_RESET)' 'user.email not set'; \
		printf '  %b%s%b\n' '$(_COLOR_DIM)' '  Run: git config --global user.email "you@example.com"' '$(_COLOR_RESET)'; \
	fi
	@if git config user.name >/dev/null 2>&1; then \
		printf '  %b%s%b %s\n' '$(_COLOR_SUCCESS)' '✓' '$(_COLOR_RESET)' "user.name = $$(git config user.name)"; \
	else \
		printf '  %b%s%b\n' '$(_COLOR_WARN)' '!' '$(_COLOR_RESET)' 'user.name not set'; \
		printf '  %b%s%b\n' '$(_COLOR_DIM)' '  Run: git config --global user.name "Your Name"' '$(_COLOR_RESET)'; \
	fi

.PHONY: doctor-git-config
doctor-git-config:
	@printf '%b%s%b\n' '$(_COLOR_BOLD)' 'git-config' '$(_COLOR_RESET)'
	@if git config user.email >/dev/null 2>&1; then \
		printf '  %b%s%b %s\n' '$(_COLOR_SUCCESS)' '✓' '$(_COLOR_RESET)' "user.email = $$(git config user.email)"; \
	else \
		printf '  %b%s%b %s\n' '$(_COLOR_ERROR)' '✗' '$(_COLOR_RESET)' 'user.email not set'; \
		printf '  %b%s%b\n' '$(_COLOR_DIM)' '  Fix: git config --global user.email "you@example.com"' '$(_COLOR_RESET)'; \
	fi
	@if git config user.name >/dev/null 2>&1; then \
		printf '  %b%s%b %s\n' '$(_COLOR_SUCCESS)' '✓' '$(_COLOR_RESET)' "user.name = $$(git config user.name)"; \
	else \
		printf '  %b%s%b %s\n' '$(_COLOR_ERROR)' '✗' '$(_COLOR_RESET)' 'user.name not set'; \
		printf '  %b%s%b\n' '$(_COLOR_DIM)' '  Fix: git config --global user.name "Your Name"' '$(_COLOR_RESET)'; \
	fi

###############################################################################
# HELP
###############################################################################

.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  setup            Complete environment setup (default)"
	@echo "  require          Validate environment (read-only, fail-fast)"
	@echo "  doctor           Diagnose and troubleshoot issues"
	@echo "  install-symlinks Create symlinks for dotfiles"
	@echo "  help             Show this help"
