# shellcheck shell=sh
# =============================================================================
# 20-node.sh - node.js / nvm PATH
# =============================================================================
#
# Adds nvm's default node version to PATH without sourcing nvm.sh.
# Reads $NVM_DIR/alias/default; "node" or empty = highest installed.
# Full nvm command is loaded by ~/.zshrc for interactive use.
# =============================================================================

export NVM_DIR="$HOME/.nvm"

if [ -d "$NVM_DIR/versions/node" ]; then
    _nvm_ver=""
    [ -r "$NVM_DIR/alias/default" ] \
        && IFS= read -r _nvm_ver < "$NVM_DIR/alias/default"

    # Empty glob_ver matches all versions (highest wins via sort -V).
    _nvm_glob=""
    [ -n "$_nvm_ver" ] && [ "$_nvm_ver" != "node" ] && _nvm_glob="$_nvm_ver"

    # shellcheck disable=SC2012  # ls + sort -V is the cleanest version-aware sort
    _nvm_bin=$(ls -d "$NVM_DIR"/versions/node/v"$_nvm_glob"*/bin 2>/dev/null \
        | sort -V | tail -1)

    [ -n "$_nvm_bin" ] && PATH="$_nvm_bin:$PATH"
    unset _nvm_ver _nvm_glob _nvm_bin
fi
