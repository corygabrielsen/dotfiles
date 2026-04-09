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

# nvm — add default node to PATH (mirrors .zshenv setup for bash)
export NVM_DIR="$HOME/.nvm"
if [[ -d "$NVM_DIR/versions/node" ]]; then
    _nvm_ver=$(<"$NVM_DIR/alias/default" 2>/dev/null)
    if [[ "$_nvm_ver" == "node" || -z "$_nvm_ver" ]]; then
        # "node" alias = latest installed; pick highest version
        _nvm_node_bin=$(ls -d "$NVM_DIR"/versions/node/v*/bin 2>/dev/null | sort -V | tail -1)
    else
        _nvm_node_bin=$(ls -d "$NVM_DIR"/versions/node/v${_nvm_ver}*/bin 2>/dev/null | sort -V | tail -1)
    fi
    [[ -n "$_nvm_node_bin" ]] && PATH="$_nvm_node_bin:$PATH"
    unset _nvm_ver _nvm_node_bin
fi

# go
if [[ -d /usr/local/go ]]; then
    PATH="/usr/local/go/bin:$PATH"
    export GOPATH="$HOME/go"
fi

# rust
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# bun
[[ -d "$HOME/.bun/bin" ]] && PATH="$HOME/.bun/bin:$PATH"

# user binaries
[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"

export PATH

# Non-interactive editors and pagers
export EDITOR=cat
export VISUAL=cat
export PAGER=cat
export GIT_PAGER=cat
export LESS="-R --quit-if-one-screen --no-init"

# Non-interactive operation
export DEBIAN_FRONTEND=noninteractive
export PYTHONUNBUFFERED=1
