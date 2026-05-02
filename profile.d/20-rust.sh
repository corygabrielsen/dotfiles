# shellcheck shell=sh
# =============================================================================
# 20-rust.sh - Rust (cargo) and Foundry toolchains
# =============================================================================
#
# Foundry is appended (not prepended) so it doesn't shadow system tools
# named `cast`, `forge`, etc.
# =============================================================================

# shellcheck disable=SC1091  # rustup-managed file, not part of repo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

for _foundry in "$HOME/.foundry/bin" "/usr/local/foundry/bin"; do
    if [ -d "$_foundry" ]; then
        PATH="$PATH:$_foundry"
        break
    fi
done
unset _foundry
