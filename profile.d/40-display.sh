# shellcheck shell=sh
# =============================================================================
# 40-display.sh - X11 DISPLAY for GUI apps (macOS only)
# =============================================================================
#
# Linux/WSL set DISPLAY through their window-system layer.
#
# Recomputes DISPLAY when en0 has an address — refreshes after network
# changes, tmux pane reattach after sleep, etc., so XQuartz can be
# reached. When `ipconfig getifaddr en0` returns nothing (Wi-Fi off,
# active interface is not en0, or X11 is being driven via a manually
# set DISPLAY like `:0` for a local server), leave any inherited value
# alone — overriding it would break setups that intentionally point at
# a non-en0 endpoint. stderr is silenced so non-interactive shells
# don't leak interface noise.
# =============================================================================

if [ "$(command uname)" = "Darwin" ]; then
    _addr=$(command ipconfig getifaddr en0 2>/dev/null)
    if [ -n "$_addr" ]; then
        DISPLAY="$_addr:0"
        export DISPLAY
    fi
    unset _addr
fi
