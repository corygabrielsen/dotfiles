# shellcheck shell=sh
# =============================================================================
# 90-path-user.sh - User binaries (~/.local/bin)
# =============================================================================
#
# Numbered late so this prepend lands last → ~/.local/bin at the front
# of PATH. XDG $XDG_BIN_HOME convention.
# =============================================================================

[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
