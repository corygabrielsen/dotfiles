#!/bin/bash
# =============================================================================
# claude-env.sh - Claude Code per-command environment setup
# =============================================================================
#
# Sourced by Claude Code before every Bash tool invocation. Activated via
# CLAUDE_ENV_FILE=~/.claude-env.sh (set in ~/.zshenv).
#
# This file must be FAST — it runs before EVERY command. Avoid forks, file
# I/O, and slow shell init (e.g., do not source ~/.bashrc, do not run
# nvm.sh). Resolve PATH manually instead.
#
# Behavior:
#   1. Loads project-specific environment via direnv
#   2. Mirrors ~/.zshenv PATH setup (bash subprocesses don't read .zshenv)
#   3. Forces non-interactive editors/pagers so tools don't hang on $EDITOR
#
# Install: symlinked from dotfiles/claude/claude-env.sh by `make`.
# =============================================================================


# =============================================================================
# direnv
# =============================================================================
#
# Loads project-specific overrides (CARGO_HOME, GOPATH, etc.) from .envrc.
# Silenced because direnv prints a banner that would pollute tool output.

if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv export bash 2>/dev/null)"
fi


# =============================================================================
# PATH (mirrors ~/.zshenv)
# =============================================================================
#
# Bash subprocesses don't source .zshenv (zsh-only). Replicate the parts
# that matter for command resolution: node, go, rust, bun, ~/.local/bin.

# nvm — add default node to PATH without sourcing nvm.sh (~300ms).
# Resolves alias chain (default → node|lts/* → versioned dir).
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

# rust (cargo + rustup)
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# bun
[[ -d "$HOME/.bun/bin" ]] && PATH="$HOME/.bun/bin:$PATH"

# user binaries
[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"

export PATH


# =============================================================================
# Non-interactive defaults
# =============================================================================
#
# Force editors/pagers to `cat` so tools that try to spawn $EDITOR or $PAGER
# don't hang in the background waiting for input that will never come.

export EDITOR=cat
export VISUAL=cat
export PAGER=cat
export GIT_PAGER=cat
export LESS="-R --quit-if-one-screen --no-init"

export DEBIAN_FRONTEND=noninteractive
export PYTHONUNBUFFERED=1
