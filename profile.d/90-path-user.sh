# shellcheck shell=sh
# =============================================================================
# 90-path-user.sh - User binaries (~/.local/bin)
# =============================================================================
#
# Numbered late so this prepend lands last → ~/.local/bin at the front
# of PATH. XDG $XDG_BIN_HOME convention.
#
# ~/.local/bin/env is the standard hook installers (uv, rustup new layout,
# etc.) drop for additional env exports. Sourced here once ~/.local/bin
# itself is on PATH.
# =============================================================================

[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

# shellcheck disable=SC1091  # installer-managed file, not part of repo
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
