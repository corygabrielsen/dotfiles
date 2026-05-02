# shellcheck shell=sh
# =============================================================================
# 20-go.sh - Go toolchain PATH and GOPATH
# =============================================================================
#
# Append (not prepend) so a Go installed via Homebrew, asdf, Nix, or any
# other version manager wins over /usr/local/go. Matches the pre-refactor
# behavior in zsh/zshenv and the convention in dotfile repos like
# mathiasbynens/dotfiles and holman/dotfiles. /usr/local/go acts as the
# fallback when no version-manager Go is installed; otherwise the user's
# preferred toolchain stays in effect.
# =============================================================================

# `:-` so an inherited project-specific GOPATH (typically from direnv)
# wins over the default.
if [ -d /usr/local/go ]; then
    export GOPATH="${GOPATH:-$HOME/go}"
    PATH="$PATH:/usr/local/go/bin"
fi
