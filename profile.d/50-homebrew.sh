# shellcheck shell=sh
# =============================================================================
# 50-homebrew.sh - Homebrew / Linuxbrew shellenv
# =============================================================================
#
# `brew shellenv` emits the env-var exports needed for brew-installed tools
# to be on PATH (and MANPATH, INFOPATH). Locations vary by platform:
#   macOS Apple Silicon: /opt/homebrew
#   macOS Intel:         /usr/local
#   Linux (Linuxbrew):   /home/linuxbrew/.linuxbrew  or  ~/.linuxbrew
# =============================================================================

case "$(uname)" in
    Darwin)
        if [ -x /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        ;;
    Linux)
        if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
            eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
        fi
        ;;
esac
