# shellcheck shell=sh
# =============================================================================
# 40-display.sh - X11 DISPLAY for GUI apps (macOS only)
# =============================================================================
#
# Linux/WSL set DISPLAY through their window-system layer.
# =============================================================================

if [ "$(uname)" = "Darwin" ]; then
    DISPLAY="$(ipconfig getifaddr en0):0"
    export DISPLAY
fi
