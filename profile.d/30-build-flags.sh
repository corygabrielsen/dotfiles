# shellcheck shell=sh
# =============================================================================
# 30-build-flags.sh - Parallel build defaults
# =============================================================================
#
# MAKEFLAGS=-jN is honored by make and many tools (cargo build scripts,
# autotools configure pipelines). nproc on Linux, sysctl on macOS.
# =============================================================================

if command -v nproc >/dev/null 2>&1; then
    MAKEFLAGS="-j$(command nproc)"
elif [ "$(command uname)" = "Darwin" ]; then
    MAKEFLAGS="-j$(command sysctl -n hw.ncpu)"
fi

[ -n "${MAKEFLAGS:-}" ] && export MAKEFLAGS
