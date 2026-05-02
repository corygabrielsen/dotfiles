# shellcheck shell=sh
# =============================================================================
# 99-local.sh - Per-machine override
# =============================================================================
#
# Sources ~/.profile.local if present. Gitignored — not in the repo.
# =============================================================================

# shellcheck disable=SC1091  # per-machine, not part of repo
[ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"
