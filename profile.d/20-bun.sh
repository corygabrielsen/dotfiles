# shellcheck shell=sh
# =============================================================================
# 20-bun.sh - bun runtime PATH
# =============================================================================
#
# `:-` so an inherited BUN_INSTALL (e.g., from direnv on a project that
# pins a per-repo bun install) wins over the default. Standard idiom for
# tool-prefix env vars.
# =============================================================================

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
[ -d "$BUN_INSTALL/bin" ] && PATH="$BUN_INSTALL/bin:$PATH"
