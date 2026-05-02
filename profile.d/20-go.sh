# shellcheck shell=sh
# =============================================================================
# 20-go.sh - Go toolchain PATH and GOPATH
# =============================================================================

if [ -d /usr/local/go ]; then
    PATH="/usr/local/go/bin:$PATH"
    export GOPATH="$HOME/go"
fi
