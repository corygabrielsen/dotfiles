#!/bin/bash
###############################################################################
# Claude Code Environment Setup
###############################################################################
#
# This file is sourced by Claude Code before each Bash command.
# Symlinked to ~/.claude-env.sh by dotfiles install.py
# Activated via CLAUDE_ENV_FILE in ~/.zshenv
#
# Keep this file fast - it runs before EVERY command.
#
###############################################################################

# Load direnv for project-specific environment variables (CARGO_HOME, etc.)
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv export bash 2>/dev/null)"
fi

# Non-interactive editors and pagers
export EDITOR=cat
export VISUAL=cat
export PAGER=cat
export GIT_PAGER=cat
export LESS="-R --quit-if-one-screen --no-init"

# Non-interactive operation
export DEBIAN_FRONTEND=noninteractive
export PYTHONUNBUFFERED=1
