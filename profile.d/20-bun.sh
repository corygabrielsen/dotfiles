# shellcheck shell=sh
# =============================================================================
# 20-bun.sh - bun runtime PATH
# =============================================================================

export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && PATH="$BUN_INSTALL/bin:$PATH"
